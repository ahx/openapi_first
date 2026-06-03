# frozen_string_literal: true

require_relative 'builder'
require 'forwardable'

module OpenapiFirst
  # Represents an OpenAPI API Description document
  # This is returned by OpenapiFirst.load.
  class Definition
    extend Forwardable

    # @return [String,nil]
    attr_reader :filepath
    # @return [String,nil]
    attr_reader :path_prefix
    # @return [Configuration]
    attr_reader :config
    # @return [Enumerable[String]]
    attr_reader :paths
    # @return [Router]
    attr_reader :router

    # @param contents [Hash] The OpenAPI document.
    # @param filepath [String] The file path of the OpenAPI document.
    # @param path_prefix [String,nil] An optional path prefix, that is not documented, that all requests begin with.
    def initialize(contents, filepath = nil, path_prefix = nil)
      @filepath = filepath
      @path_prefix = path_prefix
      @config = OpenapiFirst.configuration.child
      yield @config if block_given?
      @config.freeze
      @router = Builder.build_router(contents, filepath:, config:)
      @resolved = contents
      @paths = @router.routes.map(&:path).to_a.uniq # TODO: Refactor
    end

    # Gives access to the raw resolved Hash. Like `mydefinition['components'].dig('schemas', 'Stations')`
    # @!method [](key)
    # @return [Hash]
    def_delegators :@resolved, :[]

    # Returns an Enumerable of available Routes for this API description.
    # @!method routes
    # @return [Enumerable[Router::Route]]
    def_delegators :@router, :routes

    # @return [String,nil] The title from the OpenAPI document's `info.title`, if any.
    def title
      self['info']&.[]('title')
    end

    # Returns a unique identifier for this API definition
    # @return [String] A unique key for this API definition
    def key
      return filepath if filepath

      info = self['info'] || {}
      title = info['title']
      version = info['version']

      if title.nil? || version.nil?
        raise ArgumentError,
              "Cannot generate key for the OpenAPI document because 'info.title' or 'info.version' is missing. " \
              'Please add these fields to your OpenAPI document.'
      end

      "#{title} @ #{version}"
    end

    def inspect
      "#<#{self.class.name} @key='#{key}'>"
    end

    # Resolves the path for the named operation, filling in any `{param}` placeholders.
    # @param operation_id [String, Symbol] An operationId present in this API description.
    # @param params [Hash] Path-parameter values keyed by name (String or Symbol).
    # @return [String] The resolved path (e.g. "/pets/42").
    # @raise [ArgumentError] if the operationId is not found or a required path parameter is missing.
    def path_for(params = {}, operation_id:)
      request_def = routes.lazy.flat_map(&:requests).find { |r| r.operation_id == operation_id.to_s }
      raise ArgumentError, "Operation #{operation_id.inspect} is not defined in #{key}." unless request_def

      request_def.path.gsub(/\{([^}]+)\}/) do
        name = Regexp.last_match(1)
        params.fetch(name.to_sym) do
          params.fetch(name) do
            raise ArgumentError, "Missing path parameter #{name.inspect} for operation #{operation_id.inspect}."
          end
        end
      end
    end

    # Validates the request against the API description.
    # @param [Rack::Request] request The Rack request object.
    # @param [Boolean] raise_error Whether to raise an error if validation fails.
    # @param [String,nil] path_template The OpenAPI path template (e.g. "/pets/{petId}") of the
    #   already-matched route. Pass this when your own router has matched the route, to skip
    #   openapi_first's path matching. Used by framework integrations like Sinatra.
    # @param [Hash,nil] path_params The path parameters extracted by your own router
    #   (e.g. { "petId" => "42" }), keyed by parameter name. Pass this together with +path_template+
    #   to skip openapi_first's path-parameter extraction; otherwise they are extracted from the path.
    # @yield [ValidatedRequest] Optional block called after successful validation.
    #   The block runs inside the same catch(FAILURE) as the after_request_validation hooks,
    #   so it may call OpenapiFirst::Failure.fail! to short-circuit and produce an error.
    # @return [ValidatedRequest] The validated request object.
    def validate_request(request, raise_error: false, path_template: nil, path_params: nil, &after_block)
      route = match_route(request, path_template, params: path_params)
      validated = if route.error
                    ValidatedRequest.new(request, error: route.error)
                  else
                    result = call_before_request_validation_hooks(request, route.request_definition)
                    result ||= route.request_definition.validate(request, route_params: route.params)
                    result.is_a?(Failure) ? ValidatedRequest.new(request, error: result) : result
                  end
      validated = call_after_request_validation_hooks(request, validated, &after_block)
      raise validated.error.exception(validated) if validated.error && raise_error

      validated
    end

    # Validates the response against the API description.
    # @param request [Rack::Request] The Rack request object.
    # @param response [Rack::Response] The Rack response object.
    # @param raise_error [Boolean] Whether to raise an error if validation fails.
    # @return [ValidatedResponse] The validated response object.
    def validate_response(request, response, raise_error: false)
      route = @router.match(request.request_method, resolve_path(request), content_type: request.content_type)
      return if route.error # Skip response validation for unknown requests

      response_match = route.match_response(status: response.status, content_type: response.content_type)
      error = response_match.error
      validated = if error
                    ValidatedResponse.new(response, error:)
                  else
                    response_match.response.validate(response)
                  end
      @config.after_response_validation&.each { |hook| hook.call(validated, request, self) }
      raise validated.error.exception(validated) if raise_error && validated.invalid?

      validated
    end

    private

    def match_route(request, path_template, params:)
      request_method = request.request_method
      content_type = request.content_type
      return @router.match_route(request_method, path_template, params:, content_type:) if path_template

      @router.match(request_method, resolve_path(request), content_type:)
    end

    def call_before_request_validation_hooks(request, request_definition)
      return if @config.before_request_validation.none?

      catch(FAILURE) do
        @config.before_request_validation.each do |hook|
          hook.call(request, request_definition, self)
        end
        nil
      end
    end

    def call_after_request_validation_hooks(request, validated)
      hooks = @config.after_request_validation
      return validated if hooks.none? && !block_given?

      error = catch(FAILURE) do
        hooks.each { |hook| hook.call(validated, self) }
        yield validated if block_given? && validated.valid?
        return validated
      end
      ValidatedRequest.new(request, error: error)
    end

    def resolve_path(rack_request)
      return rack_request.path.delete_prefix(path_prefix) if path_prefix && rack_request.path.start_with?(path_prefix)
      return rack_request.path unless @config.path

      @config.path.call(rack_request)
    end
  end
end

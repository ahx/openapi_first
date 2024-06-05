# frozen_string_literal: true

require_relative 'failure'
require_relative 'router'
require_relative 'request'
require_relative 'response'
require_relative 'builder'

module OpenapiFirst
  # Represents an OpenAPI API Description document
  # This is returned by OpenapiFirst.load.
  class Definition
    attr_reader :filepath, :config, :paths, :router

    # @param resolved [Hash] The resolved OpenAPI document.
    # @param filepath [String] The file path of the OpenAPI document.
    def initialize(resolved, filepath = nil)
      @filepath = filepath
      @config = OpenapiFirst.configuration.clone
      yield @config if block_given?
      @config.freeze
      @router = Builder.build_router(resolved, @config)
      @paths = resolved['paths'].keys # TODO: Move into builder as well
    end

    def routes
      @router.routes
    end

    # Validates the request against the API description.
    # @param rack_request [Rack::Request] The Rack request object.
    # @param raise_error [Boolean] Whether to raise an error if validation fails.
    # @return [Request] The validated request object.
    def validate_request(request, raise_error: false)
      route = @router.match(request.request_method, request.path, content_type: request.content_type)
      validated = if route.error
                    ValidatedRequest.new(request, error: route.error)
                  else
                    route.request_definition.validate(request, route_params: route.params)
                  end
      @config.hooks[:after_request_validation].each { |hook| hook.call(validated, self) }
      raise validated.error.exception if validated.error && raise_error

      validated
    end

    # Validates the response against the API description.
    # @param rack_request [Rack::Request] The Rack request object.
    # @param rack_response [Rack::Response] The Rack response object.
    # @param raise_error [Boolean] Whether to raise an error if validation fails.
    # @return [Response] The validated response object.
    def validate_response(rack_request, rack_response, raise_error: false)
      route = @router.match(rack_request.request_method, rack_request.path, content_type: rack_request.content_type)
      return if route.error # Skip response validation for unknown requests

      response_match = route.match_response(status: rack_response.status, content_type: rack_response.content_type)
      error = response_match.error
      validated = if error
                    ValidatedResponse.new(rack_response, error:)
                  else
                    response_match.response.validate(rack_response)
                  end
      @config.hooks[:after_response_validation]&.each { |hook| hook.call(validated, rack_request, self) }
      raise validated.error.exception if raise_error && validated.invalid?

      validated
    end
  end
end

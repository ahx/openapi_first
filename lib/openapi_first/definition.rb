# frozen_string_literal: true

require_relative 'definition/path_item'
require_relative 'failure'
require_relative 'router'
require_relative 'response'
require_relative 'response_matcher'
require_relative 'response_parser'
require_relative 'request_parser'
require_relative 'validated_request'
require_relative 'validated_response'
require_relative 'request_validation/validator'
require_relative 'response_validation/validator'

module OpenapiFirst
  # Represents an OpenAPI API Description document
  # This is returned by OpenapiFirst.load.
  class Definition
    attr_reader :filepath, :openapi_version, :config, :operations

    # @param resolved [Hash] The resolved OpenAPI document.
    # @param filepath [String] The file path of the OpenAPI document.
    def initialize(resolved, filepath = nil)
      @filepath = filepath
      @config = OpenapiFirst.configuration.clone
      path_items = resolved['paths'].map { |path, item| PathItem.new(path, item) }
      @openapi_version = detect_version(resolved)
      @operations = path_items.flat_map(&:operations)
      @router = Router.new
      @request_parsers = {}
      @request_validators = {}
      @response_parsers = {}
      @response_validators = {}
      @response_matchers = {}
      @operations.each do |op|
        @request_parsers[op] = RequestParser.new(
          query_parameters: op.query_parameters,
          path_parameters: op.path_parameters,
          header_parameters: op.header_parameters,
          cookie_parameters: op.cookie_parameters
        )
        op.requests.each do |request|
          @router.route(request.request_method, request.path, content_type: request.content_type, to: request)
          @request_validators[request] = RequestValidation::Validator.new(request, hooks: @config.hooks, openapi_version:)
        end
        response_matcher = ResponseMatcher.new
        op.responses.each do |response|
          @response_validators[response] = ResponseValidation::Validator.new(response, openapi_version:)
          response_matcher.add_response(response.status, response.content_type, response)
          @response_parsers[response] = ResponseParser.new(headers: response.headers, content_type: response.content_type)
        end
        @response_matchers[op] = response_matcher
      end
      yield @config if block_given?
      @config.freeze
    end

    # Validates the request against the API description.
    # @param rack_request [Rack::Request] The Rack request object.
    # @param raise_error [Boolean] Whether to raise an error if validation fails.
    # @return [Request] The validated request object.
    def validate_request(request, raise_error: false)
      validated = route_and_validate(request)
      @config.hooks[:after_request_validation].each { |hook| hook.call(validated) }
      validated.error&.raise! if raise_error
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

      operation = route.request_definition.operation
      response_match = @response_matchers[operation].match(rack_response.status, rack_response.content_type)
      error = response_match.error
      validated = if error
                    ValidatedResponse.new(rack_response, error)
                  else
                    response_definition = response_match.response
                    validator = @response_validators[response_definition]
                    parsed_response = @response_parsers[response_definition].parse(rack_response)
                    error = validator.call(parsed_response)
                    ValidatedResponse.new(parsed_response, error)
                  end
      @config.hooks[:after_response_validation]&.each { |hook| hook.call(validated) }
      validated.error&.raise! if raise_error
      validated
    end

    # Gets the PathItem object for the specified path.
    # @param pathname [String] The path template string.
    # @return [PathItem] The PathItem object.
    # Example:
    #   definition.path('/pets/{id}')
    def path(pathname)
      @router.match('GET', pathname).request_definition&.path_item
    end

    private

    def route_and_validate(request)
      route = @router.match(request.request_method, request.path, content_type: request.content_type)
      request_definition = route.request_definition
      return ValidatedRequest.new(request, error: route.error, operation: request_definition) if route.error

      operation = request_definition.operation
      parsed = @request_parsers[operation].parse(request, route_params: route.params)
      error = @request_validators[request_definition].call(parsed)
      ValidatedRequest.new(parsed, error:, operation:)
    end

    def detect_version(resolved)
      (resolved['openapi'] || resolved['swagger'])[0..2]
    end
  end
end

# frozen_string_literal: true

require_relative 'definition/path_item'
require_relative 'failure'
require_relative 'router'
require_relative 'response'
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
      path_items = resolved['paths'].map { |path, item| PathItem.new(path, item) }
      @operations = path_items.flat_map(&:operations)
      @router = Router.new
      @operations.each do |op|
        @router.add_route(op.request_method, op.path, op)
      end
      @openapi_version = detect_version(resolved)
      @config = OpenapiFirst.configuration.clone
      @request_parsers = operations.to_h { |op| [op, RequestParser.new(op)] }
      @request_validators = operations.to_h { |op| [op, RequestValidation::Validator.new(op, hooks: @config.hooks)] }
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
    def validate_response(request, rack_response, raise_error: false)
      route = @router.match(request.request_method, request.path)
      operation = route.operation
      response = OpenapiFirst::Response.new(operation, rack_response)
      validator = ResponseValidation::Validator.new(operation, openapi_version: @openapi_version)
      error = validator.call(response)
      validated = ValidatedResponse.new(response, error)
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
      @router.match('GET', pathname).operation&.path_item
    end

    private

    def route_and_validate(request)
      route = @router.match(request.request_method, request.path)
      operation = route.operation
      return ValidatedRequest.new(request, error: route.error, operation:) if route.error

      parsed = @request_parsers[operation].parse(request, route_params: route.params)
      error = @request_validators[operation].call(parsed)
      ValidatedRequest.new(parsed, error:, operation:)
    end

    def detect_version(resolved)
      (resolved['openapi'] || resolved['swagger'])[0..2]
    end
  end
end

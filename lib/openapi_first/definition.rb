# frozen_string_literal: true

require_relative 'definition/path_item'
require_relative 'runtime_request'
require_relative 'validated_request'
require_relative 'validated_response'
require_relative 'request_validation/validator'
require_relative 'response_validation/validator'

module OpenapiFirst
  # Represents an OpenAPI API Description document
  # This is returned by OpenapiFirst.load.
  class Definition
    attr_reader :filepath, :paths, :openapi_version, :config

    # @param resolved [Hash] The resolved OpenAPI document.
    # @param filepath [String] The file path of the OpenAPI document.
    def initialize(resolved, filepath = nil)
      @filepath = filepath
      @paths = resolved['paths']
      @openapi_version = detect_version(resolved)
      @config = OpenapiFirst.configuration.clone
      yield @config if block_given?
      @config.freeze
    end

    # Validates the request against the API description.
    # @param rack_request [Rack::Request] The Rack request object.
    # @param raise_error [Boolean] Whether to raise an error if validation fails.
    # @return [RuntimeRequest] The validated request object.
    def validate_request(rack_request, raise_error: false)
      runtime_request = request(rack_request)
      validator = build_request_validator(runtime_request.path_item, runtime_request.operation)

      error = validator.call(runtime_request)
      validated = ValidatedRequest.new(runtime_request, error)
      @config.hooks[:after_request_validation]&.each { |hook| hook.call(validated) }
      validated.error&.raise! if raise_error
      validated
    end

    # Validates the response against the API description.
    # @param rack_request [Rack::Request] The Rack request object.
    # @param rack_response [Rack::Response] The Rack response object.
    # @param raise_error [Boolean] Whether to raise an error if validation fails.
    # @return [RuntimeResponse] The validated response object.
    def validate_response(rack_request, rack_response, raise_error: false)
      operation = request(rack_request).operation
      runtime_response = RuntimeResponse.new(operation, rack_response)
      validator = ResponseValidation::Validator.new(operation, openapi_version: @openapi_version)
      error = validator.call(runtime_response)
      validated = ValidatedResponse.new(runtime_response, error)
      @config.hooks[:after_response_validation]&.each { |hook| hook.call(validated) }
      validated.error&.raise! if raise_error
      validated
    end

    # Builds a RuntimeRequest object based on the Rack request.
    # @param rack_request [Rack::Request] The Rack request object.
    # @return [RuntimeRequest] The RuntimeRequest object.
    def request(rack_request)
      path_item, path_params = find_path_item_and_params(rack_request.path)
      operation = path_item&.operation(rack_request.request_method.downcase)
      RuntimeRequest.new(
        request: rack_request,
        path_item:,
        operation:,
        path_params:
      )
    end

    # Gets all the operations defined in the API description.
    # @return [Array<Operation>] An array of Operation objects.
    def operations
      @paths.keys.flat_map { |pathname| path(pathname).operations }
    end

    # Gets the PathItem object for the specified path.
    # @param pathname [String] The path template string.
    # @return [PathItem] The PathItem object.
    # Example:
    #   definition.path('/pets/{id}')
    def path(pathname)
      return unless @paths.key?(pathname)

      PathItem.new(pathname, @paths[pathname])
    end

    private

    def build_request_validator(path_item, operation)
      @build_request_validator ||= Hash.new do |hash, key|
        hash[key] = RequestValidation::Validator.new(path_item, operation, config:, openapi_version:)
      end[operation&.name]
    end

    def find_path_item_and_params(request_path)
      simple = path(request_path)
      return [simple, {}] if simple

      search_for_path_item(request_path)
    end

    def search_for_path_item(request_path)
      @paths.each_key do |pathname|
        path_item = path(pathname)
        path_params = path_item.match(request_path)
        next unless path_params

        return [
          path_item,
          path_params
        ]
      end
      nil
    end

    def detect_version(resolved)
      (resolved['openapi'] || resolved['swagger'])[0..2]
    end
  end
end

# frozen_string_literal: true

require 'forwardable'
require 'openapi_parameters'
require_relative 'runtime_response'
require_relative 'body_parser'
require_relative 'request_validation/validator'

module OpenapiFirst
  # RuntimeRequest represents how an incoming request (Rack::Request) matches a request definition.
  class RuntimeRequest
    extend Forwardable

    def initialize(request:, path_item:, operation:, path_params:)
      @request = request
      @path_item = path_item
      @operation = operation
      @original_path_params = path_params
      @error = nil
      @validated = false
    end

    def_delegators :@request, :content_type, :media_type, :path
    def_delegators :@operation, :operation_id, :request_method
    def_delegator :@path_item, :path, :path_definition

    # Returns the path_item object.
    # @return [PathItem, nil] The path_item object or nil if this request path is not known.
    attr_reader :path_item

    # Returns the operation object.
    # @return [Operation, nil] The operation object or nil if this request method is not known.
    attr_reader :operation

    # Returns the error object if validation failed.
    # @return [Failure, nil]
    attr_reader :error

    # Checks if the request is valid.
    # @return [Boolean] true if the request is valid, false otherwise.
    def valid?
      validate unless @validated
      error.nil?
    end

    # Checks if the path and request method are known.
    # @return [Boolean] true if the path and request method are known, false otherwise.
    def known?
      known_path? && known_request_method?
    end

    # Checks if the path is known.
    # @return [Boolean] true if the path is known, false otherwise.
    def known_path?
      !!path_item
    end

    # Checks if the request method is known.
    # @return [Boolean] true if the request method is known, false otherwise.
    def known_request_method?
      !!operation
    end

    # Returns the merged path and query parameters.
    # @return [Hash] The merged path and query parameters.
    def params
      @params ||= query.merge(path_parameters)
    end

    # Returns the parsed path parameters of the request.
    # @return [Hash]
    def path_parameters
      return {} unless operation.path_parameters

      @path_parameters ||=
        OpenapiParameters::Path.new(operation.path_parameters).unpack(@original_path_params) || {}
    end

    # Returns the parsed query parameters.
    # This only includes parameters that are defined in the API description.
    # @note This method is aliased as query_parameters.
    # @return [Hash]
    def query
      return {} unless operation.query_parameters

      @query ||=
        OpenapiParameters::Query.new(operation.query_parameters).unpack(request.env[Rack::QUERY_STRING]) || {}
    end

    alias query_parameters query

    # Returns the parsed header parameters.
    # This only includes parameters that are defined in the API description.
    # @return [Hash]
    def headers
      return {} unless operation.header_parameters

      @headers ||= OpenapiParameters::Header.new(operation.header_parameters).unpack_env(request.env) || {}
    end

    # Returns the parsed cookie parameters.
    # This only includes parameters that are defined in the API description.
    # @return [Hash]
    def cookies
      return {} unless operation.cookie_parameters

      @cookies ||=
        OpenapiParameters::Cookie.new(operation.cookie_parameters).unpack(request.env[Rack::HTTP_COOKIE]) || {}
    end

    # Returns the parsed request body.
    # This returns the whole request body with default values applied as defined in the API description.
    # This does not remove any fields that are not defined in the API description.
    # @return [Hash, Array, String, nil] The parsed body of the request.
    def body
      @body ||= BodyParser.new.parse(request, request.media_type)
    end

    alias parsed_body body

    # Validates the request.
    # @return [Failure, nil] The Failure object if validation failed.
    def validate
      @validated = true
      @error = RequestValidation::Validator.new(operation).validate(self)
    end

    # Validates the request and raises an error if validation fails.
    def validate!
      error = validate
      error&.raise!
    end

    # Validates the response.
    # @param rack_response [Rack::Response] The rack response object.
    # @param raise_error [Boolean] Whether to raise an error if validation fails.
    # @return [RuntimeResponse] The validated response object.
    def validate_response(rack_response, raise_error: false)
      validated = response(rack_response).tap(&:validate)
      validated.error&.raise! if raise_error
      validated
    end

    # Creates a new RuntimeResponse object.
    # @param rack_response [Rack::Response] The rack response object.
    # @return [RuntimeResponse] The RuntimeResponse object.
    def response(rack_response)
      RuntimeResponse.new(operation, rack_response)
    end

    private

    attr_reader :request
  end
end

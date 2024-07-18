# frozen_string_literal: true

require 'forwardable'
require 'delegate'

module OpenapiFirst
  # A validated request. It can be valid or not.
  class ValidatedRequest < SimpleDelegator
    extend Forwardable

    def initialize(original_request, error:, parsed_values: {}, request_definition: nil)
      super(original_request)
      @parsed_values = Hash.new({}).merge(parsed_values)
      @error = error
      @request_definition = request_definition
    end

    # A Failure object if the request is invalid
    # @return [Failure, nil]
    attr_reader :error

    # The request definition if this request is defined in the API description
    # @return [Request, nil]
    attr_reader :request_definition

    # @!method operation_id
    # @return [String, nil] The OpenAPI 3 operationId
    def_delegator :request_definition, :operation_id

    # @!method operation
    # @return [Hash] The raw OpenAPI 3 operation object
    def_delegator :request_definition, :operation

    # Parsed path parameters
    # @return [Hash<String, anything>]
    def parsed_path_parameters
      @parsed_values[:path]
    end

    # Parsed query parameters. This only returns the query parameters that are defined in the OpenAPI spec.
    # @return [Hash<String, anything>]
    def parsed_query
      @parsed_values[:query]
    end

    # Parsed headers. This only returns the query parameters that are defined in the OpenAPI spec.
    # @return [Hash<String, anything>]
    def parsed_headers
      @parsed_values[:headers]
    end

    # Parsed cookies. This only returns the query parameters that are defined in the OpenAPI spec.
    # @return [Hash<String, anything>]
    def parsed_cookies
      @parsed_values[:cookies]
    end

    # Parsed body. This parses the body according to the content type.
    # Note that this returns the hole body, not only the fields that are defined in the OpenAPI spec.
    # You can use JSON Schemas `additionalProperties` or `unevaluatedProperties` to
    # returns a validation error if the body contains unknown fields.
    # @return [Hash<String, anything>]
    def parsed_body
      @parsed_values[:body]
    end

    # Checks if the request is valid.
    def valid?
      error.nil?
    end

    # Checks if the request is invalid.
    def invalid?
      !valid?
    end

    # Returns true if the request is defined.
    def known?
      request_definition != nil
    end

    # Merged path, query, body parameters.
    # Here path has the highest precedence, then query, then body.
    # @return [Hash<String, anything>]
    def parsed_params
      @parsed_params ||= parsed_body.merge(parsed_query, parsed_path_parameters)
    end
  end
end

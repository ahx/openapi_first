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

    # @!method error
    #   @return [Failure, nil] The error that occurred during validation.
    # @!method request_definition
    #   @return [Request, nil]
    attr_reader :parsed_values, :error, :request_definition

    # Openapi 3 specific
    # @!method operation
    #   @return [Hash] The OpenAPI 3 operation object
    # @!method operation_id
    #   @return [String, nil] The OpenAPI 3 operationId
    def_delegators :request_definition, :operation_id, :operation

    # Parsed path parameters
    #   @return [Hash] A string keyed hash of path parameters
    def parsed_path_parameters
      parsed_values[:path]
    end

    # Parsed query parameters. This only returns the query parameters that are defined in the OpenAPI spec.
    def parsed_query
      parsed_values[:query]
    end

    # Parsed headers. This only returns the query parameters that are defined in the OpenAPI spec.
    def parsed_headers
      parsed_values[:headers]
    end

    # Parsed cookies. This only returns the query parameters that are defined in the OpenAPI spec.
    def parsed_cookies
      parsed_values[:cookies]
    end

    # Parsed body. This parses the body according to the content type.
    # Note that this returns the hole body, not only the fields that are defined in the OpenAPI spec.
    # You can use JSON Schemas `additionalProperties` or `unevaluatedProperties` to
    # returns a validation error if the body contains unknown fields.
    def parsed_body
      parsed_values[:body]
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
    def parsed_params
      @parsed_params ||= parsed_body.merge(parsed_query, parsed_path_parameters)
    end
  end
end

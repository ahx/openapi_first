# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  # A validated request. It can be valid or not.
  class ValidatedRequest
    extend Forwardable

    def initialize(parsed_values, error:, request_definition:)
      @parsed_values = parsed_values
      @error = error
      @request_definition = request_definition
    end

    def_delegators :@parsed_values, :path_parameters, :query, :headers, :cookies, :body

    alias parsed_body body
    alias query_parameters query

    # OpenAPI 3 specific Operation
    def operation
      @request_definition&.operation
    end

    def operation_id
      operation&.operation_id
    end

    # Returns the error object if validation failed.
    # @return [Failure, nil]
    attr_reader :error

    attr_reader :request_definition

    # Checks if the request is valid.
    # @return [Boolean] true if the request is valid, false otherwise.
    def valid?
      error.nil?
    end

    def known?
      request_definition != nil
    end

    def params
      @params ||= query.merge(path_parameters)
    end
  end
end

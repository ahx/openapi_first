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

    attr_reader :parsed_values, :error, :request_definition

    # Openapi 3 specific
    def_delegators :request_definition, :operation_id, :operation

    def parsed_path_parameters
      parsed_values[:path]
    end

    def parsed_query
      parsed_values[:query]
    end

    def parsed_headers
      parsed_values[:headers]
    end

    def parsed_cookies
      parsed_values[:cookies]
    end

    def parsed_body
      parsed_values[:body]
    end

    # Checks if the request is valid.
    # @return [Boolean] true if the request is valid, false otherwise.
    def valid?
      error.nil?
    end

    def invalid?
      !valid?
    end

    def known?
      request_definition != nil
    end

    # Merge path, query, body
    def parsed_params
      @parsed_params ||= parsed_body.merge(parsed_query, parsed_path_parameters)
    end
  end
end

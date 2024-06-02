# frozen_string_literal: true

require 'forwardable'
require 'delegate'

module OpenapiFirst
  # A validated request. It can be valid or not.
  class ValidatedRequest < SimpleDelegator
    extend Forwardable

    def initialize(original_request, error:, parsed_values: nil, request_definition: nil)
      super(original_request)
      @parsed_values = parsed_values
      @error = error
      @request_definition = request_definition
    end

    attr_reader :parsed_values, :error, :request_definition

    def_delegators :request_definition, :operation_id
    def_delegators :parsed_values, :parsed_path_parameters, :parsed_query, :parsed_headers, :parsed_cookies, :parsed_body

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

    def parsed_params
      @parsed_params ||= parsed_query.merge(parsed_path_parameters)
    end
  end
end

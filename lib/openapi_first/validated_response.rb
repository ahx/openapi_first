# frozen_string_literal: true

require 'forwardable'
require 'delegate'

module OpenapiFirst
  # A validated response. It can be valid or not.
  class ValidatedResponse < SimpleDelegator
    extend Forwardable

    def initialize(original_response, error:, parsed_values: nil, response_definition: nil)
      super(original_response)
      @error = error
      @parsed_values = parsed_values
      @response_definition = response_definition
    end

    attr_reader :parsed_values, :error, :response_definition

    def_delegator :parsed_values, :headers, :parsed_headers
    def_delegator :parsed_values, :body, :parsed_body

    # Checks if the response is valid.
    # @return [Boolean] true if the response is valid, false otherwise.
    def valid?
      error.nil?
    end

    def invalid?
      !valid?
    end
  end
end

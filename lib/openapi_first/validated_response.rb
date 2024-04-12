# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  # A validated response (see Response). It can be valid or not.
  class ValidatedResponse
    extend Forwardable

    def initialize(response, error)
      @response = response
      @error = error
    end

    def_delegators :@response, :body, :headers, :status, :content_type, :name, :operation, :known?, :known_status?

    # Returns the error object if validation failed.
    # @return [Failure, nil]
    attr_reader :error

    # Checks if the response is valid.
    # @return [Boolean] true if the response is valid, false otherwise.
    def valid?
      error.nil?
    end
  end
end

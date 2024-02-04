# frozen_string_literal: true

module OpenapiFirst
  # Global configuration. Currently only used for the request validation middleware.
  class Configuration
    def initialize
      @request_validation_error_response = OpenapiFirst.find_plugin(:default)::ErrorResponse
      @request_validation_raise_error = false
    end

    attr_reader :request_validation_error_response
    attr_accessor :request_validation_raise_error

    def request_validation_error_response=(mod)
      @request_validation_error_response = if mod.is_a?(Symbol)
                                             OpenapiFirst.find_plugin(:default)::ErrorResponse
                                           else
                                             mod
                                           end
    end
  end
end

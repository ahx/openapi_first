# frozen_string_literal: true

module OpenapiFirst
  class Configuration
    def initialize
      @request_validation_error_response = OpenapiFirst.plugin(:default)::ErrorResponse
      @request_validation_raise_error = false
    end

    attr_reader :request_validation_error_response
    attr_accessor :request_validation_raise_error

    def request_validation_error_response=(mod)
      @request_validation_error_response = if mod.is_a?(Symbol)
                                             OpenapiFirst.plugin(:default)::ErrorResponse
                                           else
                                             mod
                                           end
    end
  end
end

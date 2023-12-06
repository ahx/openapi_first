# frozen_string_literal: true

module OpenapiFirst
  class Configuration
    def initialize
      @error_response = OpenapiFirst.plugin(:default)::ErrorResponse
      @request_validation_raise_error = false
    end

    attr_reader :error_response, :request_validation_raise_error

    def error_response=(mod)
      @error_response = if mod.is_a?(Symbol)
                          OpenapiFirst.plugin(:default)::ErrorResponse
                        else
                          mod
                        end
    end
  end
end

# frozen_string_literal: true

module OpenapiFirst
  class Config
    def initialize(error_response: :default, request_validation_raise_error: false)
      @error_response = Plugins.plugin(error_response)::ErrorResponse
      @request_validation_raise_error = request_validation_raise_error
    end

    attr_reader :error_response, :request_validation_raise_error

    def self.default_options
      @default_options ||= new
    end

    def self.default_options=(options)
      @default_options = new(**options)
    end
  end
end

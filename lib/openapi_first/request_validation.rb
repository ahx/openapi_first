# frozen_string_literal: true

require 'rack'
require 'multi_json'
require_relative 'request_validation/request_body_validator'
require_relative 'request_validation/failure'
require 'openapi_parameters'
require_relative 'request_validation/middleware'

module OpenapiFirst
  module RequestValidation
    FAIL = :request_validation_failed

    # @param error_type [Symbol] See RequestValidation::Failure::TYPES
    # @param validation_result [OpenapiFirst::Schema::ValidationResult]
    def self.fail!(error_type, message: nil, validation_result: nil)
      throw FAIL, RequestValidation::Failure.new(
        error_type,
        message:,
        validation_result:
      )
    end

    def self.new(app, options = {})
      Middleware.new(app, options)
    end
  end
end

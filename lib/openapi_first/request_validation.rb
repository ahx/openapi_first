# frozen_string_literal: true

require 'rack'
require 'multi_json'
require_relative 'request_validation/request_body_validator'
require_relative 'request_validation/failure'
require 'openapi_parameters'
require_relative 'middlewares/request_validation'

module OpenapiFirst
  module RequestValidation
    FAIL = :request_validation_failed

    # @param error_type [Symbol] See RequestValidation::Failure::TYPES
    # @param errors [Array<OpenapiFirst::Schema::ValidationResult>]
    def self.fail!(error_type, message: nil, errors: nil)
      throw FAIL, RequestValidation::Failure.new(
        error_type,
        message:,
        errors:
      )
    end

    def self.new(app, options = {})
      OpenapiFirst::Middlewares::RequestValidation.new(app, options)
    end
  end
end

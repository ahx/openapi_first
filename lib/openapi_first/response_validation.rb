# frozen_string_literal: true

require 'multi_json'
require_relative 'response_validation/failure'
require_relative 'middlewares/response_validation'

module OpenapiFirst
  module ResponseValidation
    FAILURE = :openapi_first_validation_failure

    # @param error_type [Symbol] See ResponseValidation::Failure::TYPES
    # @param errors [Array<OpenapiFirst::Schema::ValidationResult>]
    def self.fail!(error_type, message: nil, errors: nil)
      throw FAILURE, ResponseValidation::Failure.new(
        error_type,
        message:,
        errors:
      )
    end

    def self.new(app, options = {})
      OpenapiFirst::Middlewares::ResponseValidation.new(app, options)
    end
  end
end

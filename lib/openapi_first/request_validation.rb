# frozen_string_literal: true

require 'rack'
require 'multi_json'
require_relative 'use_router'
require_relative 'request_validation/request_body_validator'
require_relative 'request_validation/failure'
require 'openapi_parameters'
require_relative 'request_validation/middleware'

module OpenapiFirst
  module RequestValidation
    FAIL = :request_validation_failed
    private_constant :FAIL

    # @param status [Integer] The intended HTTP status code (usually 400)
    # @param location [Symbol] One of :body, :header, :cookie, :query, :path
    # @param schema_validation [OpenapiFirst::Schema::ValidationResult]
    def self.fail!(status, location, message: nil, schema_validation: nil)
      throw FAIL, RequestValidation::Failure.new(
        status:,
        location:,
        message:,
        schema_validation:
      )
    end

    def self.new(app, options = {})
      Middleware.new(app, options)
    end
  end
end

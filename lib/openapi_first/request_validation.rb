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
    # @param validation_result [OpenapiFirst::Schema::ValidationResult]
    def self.fail!(location, status: 400, message: nil, validation_result: nil)
      throw FAIL, RequestValidation::Failure.new(
        status:,
        location:,
        message:,
        validation_result:
      )
    end

    def self.new(app, options = {})
      Middleware.new(app, options)
    end
  end
end

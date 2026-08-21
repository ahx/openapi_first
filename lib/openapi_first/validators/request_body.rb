# frozen_string_literal: true

require_relative 'multipart_request_body'

module OpenapiFirst
  module Validators
    class RequestBody
      MULTIPART = %r{\Amultipart/}i
      private_constant :MULTIPART

      REQUIREMENT = lambda do |parsed_request|
        Failure.new(:invalid_body, message: 'Request body must not be empty') if parsed_request.body.nil?
      end
      private_constant :REQUIREMENT

      def self.for(content_schema:, required_request_body:, content_type:)
        validators = []
        validators << REQUIREMENT if required_request_body
        klass = MULTIPART.match?(content_type.to_s) ? MultipartRequestBody : self
        validators << klass.new(content_schema:)
        validators
      end

      def initialize(content_schema:)
        @schema = content_schema
      end

      def call(parsed_request)
        body = parsed_request.body
        return if body.nil?

        validation = Schema::ValidationResult.new(
          @schema.validate(body, access_mode: 'write')
        )
        Failure.new(:invalid_body, errors: validation.errors) if validation.error?
      end
    end
  end
end

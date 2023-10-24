# frozen_string_literal: true

module OpenapiFirst
  module Validators
    class RequestBodyValidator
      def initialize(operation, env)
        @operation = operation
        @env = env
      end

      def call(parsed_request_body)
        content_type = Rack::Request.new(@env).content_type
        validate_request_content_type!(@operation, content_type)
        validate_request_body!(@operation, parsed_request_body, content_type)
      end

      private

      def validate_request_content_type!(operation, content_type)
        operation.valid_request_content_type?(content_type) || OpenapiFirst.error!(415)
      end

      def validate_request_body!(operation, body, content_type)
        validate_request_body_presence!(body, operation)
        return if content_type.nil?

        schema = operation&.request_body_schema(content_type)
        return unless schema

        validation_result = schema.validate(body)
        OpenapiFirst.error!(400, :request_body, validation_result:) if validation_result.error?
        body
      end

      def validate_request_body_presence!(body, operation)
        return unless operation.request_body['required'] && body.nil?

        OpenapiFirst.error!(400, :request_body, title: 'Request body is required')
      end
    end
  end
end

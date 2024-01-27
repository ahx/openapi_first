# frozen_string_literal: true

require_relative '../failure'

module OpenapiFirst
  module RequestValidation
    class RequestBodyValidator # :nodoc:
      def initialize(operation)
        @operation = operation
      end

      def validate!(parsed_request_body, request_content_type)
        request_body = operation.request_body
        schema = request_body.schema_for(request_content_type)
        unless schema
          Failure.fail!(:unsupported_media_type,
                        message: "Unsupported Media Type '#{request_content_type}'")
        end

        if request_body.required? && parsed_request_body.nil?
          Failure.fail!(:invalid_body,
                        message: 'Request body is not defined')
        end

        validate_body!(parsed_request_body, schema)
      end

      private

      attr_reader :operation

      def validate_body!(parsed_request_body, schema)
        request_body_schema = schema
        return unless request_body_schema

        validation = request_body_schema.validate(parsed_request_body)
        Failure.fail!(:invalid_body, errors: validation.errors) if validation.error?
      end
    end
  end
end

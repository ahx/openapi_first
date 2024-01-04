# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    class RequestBodyValidator
      def initialize(operation)
        @operation = operation
      end

      def validate!(parsed_request_body, request_content_type)
        request_body = operation.request_body
        return unless request_body

        schema = request_body.schema_for(request_content_type)
        unless schema
          RequestValidation.fail!(:unsupported_media_type,
                                  message: "Unsupported Media Type '#{request_content_type}'")
        end

        if request_body.required? && parsed_request_body.nil?
          RequestValidation.fail!(:invalid_body,
                                  message: 'Request body is not defined')
        end

        validate_body!(parsed_request_body, schema)
        parsed_request_body
      end

      private

      attr_reader :operation

      def validate_body!(parsed_request_body, schema)
        request_body_schema = schema
        return unless request_body_schema

        validation_result = request_body_schema.validate(parsed_request_body)
        RequestValidation.fail!(:invalid_body, validation_result:) if validation_result.error?
      end
    end
  end
end

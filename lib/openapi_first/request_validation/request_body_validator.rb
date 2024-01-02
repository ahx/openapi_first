# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    class RequestBodyValidator
      def initialize(operation)
        @operation = operation
      end

      def validate!(runtime_request)
        request_body = operation.request_body
        return unless request_body

        request_content_type = runtime_request.content_type
        schema = request_body.schema_for(request_content_type)
        RequestValidation.fail!(:header, status: 415) unless schema

        parsed_request_body = runtime_request.body
        RequestValidation.fail!(:body) if request_body.required? && parsed_request_body.nil?

        validate_body!(parsed_request_body, schema)
        parsed_request_body
      rescue BodyParser::ParsingError => e
        RequestValidation.fail!(:body, message: e.message)
      end

      private

      attr_reader :operation

      def validate_body!(parsed_request_body, schema)
        request_body_schema = schema
        return unless request_body_schema

        validation_result = request_body_schema.validate(parsed_request_body)
        RequestValidation.fail!(:body, validation_result:) if validation_result.error?
      end
    end
  end
end

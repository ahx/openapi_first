# frozen_string_literal: true

require_relative 'body_parser'

module OpenapiFirst
  module RequestValidation
    class RequestBodyValidator
      def initialize(operation, env)
        @operation = operation
        @env = env
      end

      def validate!
        request_body = @operation.request_body
        return unless request_body

        request_content_type = Rack::Request.new(@env).content_type
        schema = request_body.schema_for(request_content_type)
        RequestValidation.fail!(415, :header) unless schema

        parsed_request_body = BodyParser.new.parse_body(@env)
        RequestValidation.fail!(400, :body) if request_body.required? && parsed_request_body.nil?

        validate_body!(parsed_request_body, schema)
        parsed_request_body
      rescue BodyParsingError => e
        RequestValidation.fail!(400, :body, message: e.message)
      end

      private

      def validate_body!(parsed_request_body, schema)
        request_body_schema = schema
        return unless request_body_schema

        schema_validation = request_body_schema.validate(parsed_request_body)
        RequestValidation.fail!(400, :body, schema_validation:) if schema_validation.error?
      end
    end
  end
end

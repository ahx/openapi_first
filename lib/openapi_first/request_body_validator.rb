# frozen_string_literal: true

module OpenapiFirst
  class RequestBodyValidator
    def initialize(operation, env)
      @operation = operation
      @env = env
    end

    def validate!
      return unless @operation.request_body

      content_type = Rack::Request.new(@env).content_type
      validate_request_content_type!(@operation, content_type)
      parsed_request_body = BodyParser.new.parse_body(@env)
      validate_request_body!(@operation, parsed_request_body, content_type)
      parsed_request_body
    rescue BodyParsingError => e
      RequestValidation.fail!(400, :body, message: e.message)
    end

    private

    def validate_request_content_type!(operation, content_type)
      operation.valid_request_content_type?(content_type) || RequestValidation.fail!(415, :header)
    end

    def validate_request_body!(operation, body, content_type)
      validate_request_body_presence!(body, operation)
      return if content_type.nil?

      schema = operation&.request_body_schema(content_type)
      return unless schema

      schema_validation = schema.validate(body)
      RequestValidation.fail!(400, :body, schema_validation:) if schema_validation.error?
    end

    def validate_request_body_presence!(body, operation)
      return unless operation.request_body['required'] && body.nil?

      RequestValidation.fail!(400, :body)
    end
  end
end

# frozen_string_literal: true

require_relative '../error_response'

module OpenapiFirst
  module Validators
    module RequestBodyValidator
      class << self
        def call(operation, env, parsed_request_body)
          content_type = Rack::Request.new(env).content_type
          validate_request_content_type!(operation, content_type)
          validate_request_body!(operation, parsed_request_body, content_type)
        end

        private

        def validate_request_content_type!(operation, content_type)
          operation.valid_request_content_type?(content_type) || ErrorResponse.throw_error(415)
        end

        def validate_request_body!(operation, body, content_type)
          validate_request_body_presence!(body, operation)
          return if content_type.nil?

          schema = operation&.request_body_schema(content_type)
          return unless schema

          errors = schema.validate(body)
          ErrorResponse.throw_error(400, serialize_request_body_errors(errors)) if errors.any?
          body
        end

        def validate_request_body_presence!(body, operation)
          return unless operation.request_body['required'] && body.nil?

          ErrorResponse.throw_error(415, 'Request body is required')
        end

        def serialize_request_body_errors(validation_errors)
          validation_errors.map do |error|
            {
              source: {
                pointer: error['data_pointer']
              }
            }.update(ErrorFormat.error_details(error))
          end
        end
      end
    end
  end
end

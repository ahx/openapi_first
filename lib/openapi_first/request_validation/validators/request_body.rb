# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module Validators
      class RequestBody
        def self.for(request_definition, openapi_version:, hooks: {})
          schema = request_definition.content_schema
          return unless schema

          after_property_validation = hooks[:after_request_body_property_validation]

          new(Schema.new(schema, after_property_validation:, openapi_version:),
              required: request_definition.required_request_body?)
        end

        def initialize(schema, required:)
          @schema = schema
          @required = required
        end

        def call(request)
          request_body = read_body(request)
          if request_body.nil?
            Failure.fail!(:invalid_body, message: 'Request body is not defined') if @required
            return
          end

          validation = @schema.validate(request_body)
          Failure.fail!(:invalid_body, errors: validation.errors) if validation.error?
        end

        private

        def read_body(request)
          request.body
        rescue ParseError => e
          Failure.fail!(:invalid_body, message: e.message)
        end
      end
    end
  end
end

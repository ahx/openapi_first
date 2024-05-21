# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module Validators
      class RequestBody
        def self.for(request_definition, openapi_version:, hooks: {})
          request_body = request_definition.request_body
          return unless request_body

          after_property_validation = hooks[:after_request_body_property_validation]
          new(request_body, after_property_validation:, openapi_version:)
        end

        def initialize(request_body_def, after_property_validation:, openapi_version:)
          @request_body_def = request_body_def
          @after_property_validation = after_property_validation
          @openapi_version = openapi_version
        end

        attr_reader :request_body_def, :after_property_validation, :openapi_version

        def required?
          request_body_def.required?
        end

        def call(request)
          request_body = read_body(request)

          if required? && request_body.nil?
            Failure.fail!(:invalid_body,
                          message: 'Request body is not defined')
          end

          schema = request_body_def.schema_for(request.content_type)

          unless schema
            Failure.fail!(:unsupported_media_type,
                          message: "Unsupported Media Type '#{request.content_type}'")
          end

          validation = Schema.new(schema, after_property_validation:, openapi_version:).validate(request_body)
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

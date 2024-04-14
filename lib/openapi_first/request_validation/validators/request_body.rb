# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module Validators
      class RequestBody
        def self.for(request_definition)
          request_body_def = request_definition&.request_body
          return unless request_body_def

          new(request_body_def)
        end

        def initialize(request_body_def)
          @request_body_def = request_body_def
        end

        attr_reader :request_body_def

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

          validation = schema.validate(request_body)
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

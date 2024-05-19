# frozen_string_literal: true

module OpenapiFirst
  module ResponseValidation
    module Validators
      class ResponseBody
        def self.for(response_definition)
          schema = response_definition&.content_schema
          return unless schema

          new(Schema.new(schema, write: false))
        end

        def initialize(schema)
          @schema = schema
        end

        attr_reader :schema

        def call(response)
          begin
            parsed_body = response.body
          rescue ParseError => e
            Failure.fail!(:invalid_response_body, message: e.message)
          end
          validation = schema.validate(parsed_body)
          Failure.fail!(:invalid_response_body, errors: validation.errors) if validation.error?
        end
      end
    end
  end
end

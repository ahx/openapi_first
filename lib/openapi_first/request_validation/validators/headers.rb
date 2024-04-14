# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module Validators
      class Headers
        def self.for(request_definition)
          schema = request_definition&.header_schema
          return unless schema

          new(schema)
        end

        def initialize(schema)
          @schema = schema
        end

        attr_reader :schema

        def call(request)
          validation = schema.validate(request.headers)
          Failure.fail!(:invalid_header, errors: validation.errors) if validation.error?
        end
      end
    end
  end
end

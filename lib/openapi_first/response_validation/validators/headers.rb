# frozen_string_literal: true

module OpenapiFirst
  module ResponseValidation
    module Validators
      class Headers
        def self.for(response_definition)
          schema = response_definition&.headers_schema
          return unless schema

          new(schema)
        end

        def initialize(schema)
          @schema = schema
        end

        attr_reader :schema

        def call(request)
          validation = Schema.new(schema).validate(request.headers)
          Failure.fail!(:invalid_response_header, errors: validation.errors) if validation.error?
        end
      end
    end
  end
end

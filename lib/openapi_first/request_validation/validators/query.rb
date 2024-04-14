# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module Validators
      class Query
        def self.for(request_definition)
          schema = request_definition&.query_schema
          return unless schema

          new(schema)
        end

        def initialize(schema)
          @schema = schema
        end

        attr_reader :schema

        def call(request)
          validation = schema.validate(request.query)
          Failure.fail!(:invalid_query, errors: validation.errors) if validation.error?
        end
      end
    end
  end
end

# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module Validators
      class PathParameters
        def self.for(request_definition)
          schema = request_definition&.path_schema
          return unless schema

          new(schema)
        end

        def initialize(schema)
          @schema = schema
        end

        attr_reader :schema

        def call(request)
          validation = @schema.validate(request.path_parameters)
          Failure.fail!(:invalid_path, errors: validation.errors) if validation.error?
        end
      end
    end
  end
end

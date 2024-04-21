# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module Validators
      class Cookies
        def self.for(request_definition, hooks: {})
          schema = request_definition&.cookie_schema
          return unless schema

          after_property_validation = hooks[:after_request_parameter_property_validation]
          new(schema, after_property_validation:)
        end

        def initialize(schema, after_property_validation:)
          @schema = Schema.new(schema, after_property_validation:)
        end

        attr_reader :schema

        def call(request)
          validation = schema.validate(request.cookies)
          Failure.fail!(:invalid_cookie, errors: validation.errors) if validation.error?
        end
      end
    end
  end
end

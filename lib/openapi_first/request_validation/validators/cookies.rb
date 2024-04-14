# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module Validators
      class Cookies
        def self.for(request_definition)
          schema = request_definition&.cookie_schema
          return unless schema

          new(schema)
        end

        def initialize(schema)
          @schema = schema
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

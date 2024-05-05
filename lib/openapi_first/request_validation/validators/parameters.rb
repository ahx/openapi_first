# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module Validators
      class Headers < Data.define(:schema)
        def call(request)
          validation = schema.validate(request.headers)
          Failure.fail!(:invalid_header, errors: validation.errors) if validation.error?
        end
      end

      class Path < Data.define(:schema)
        def call(request)
          validation = schema.validate(request.path_parameters)
          Failure.fail!(:invalid_path, errors: validation.errors) if validation.error?
        end
      end

      class Query < Data.define(:schema)
        def call(request)
          validation = schema.validate(request.query)
          Failure.fail!(:invalid_query, errors: validation.errors) if validation.error?
        end
      end

      class Cookies < Data.define(:schema)
        def call(request)
          validation = schema.validate(request.cookies)
          Failure.fail!(:invalid_cookie, errors: validation.errors) if validation.error?
        end
      end

      class Parameters
        VALIDATORS = {
          path_schema: Path,
          query_schema: Query,
          header_schema: Headers,
          cookie_schema: Cookies
        }.freeze

        def self.for(operation, hooks: {})
          after_property_validation = hooks[:after_request_parameter_property_validation]
          validators = VALIDATORS.filter_map do |key, klass|
            schema = operation.send(key)
            klass.new(Schema.new(schema, after_property_validation:)) if schema
          end
          return if validators.empty?

          new(validators)
        end

        def initialize(validators)
          @validators = validators
        end

        def call(request)
          @validators.each { |validator| validator.call(request) }
        end
      end
    end
  end
end

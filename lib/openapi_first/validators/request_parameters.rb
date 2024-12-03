# frozen_string_literal: true

module OpenapiFirst
  module Validators
    module RequestParameters
      RequestHeaders = Data.define(:schema) do
        def call(parsed_values)
          validation = schema.validate(parsed_values[:headers])
          Failure.fail!(:invalid_header, errors: validation.errors) if validation.error?
        end
      end

      Path = Data.define(:schema) do
        def call(parsed_values)
          validation = schema.validate(parsed_values[:path])
          Failure.fail!(:invalid_path, errors: validation.errors) if validation.error?
        end
      end

      Query = Data.define(:schema) do
        def call(parsed_values)
          validation = schema.validate(parsed_values[:query])
          Failure.fail!(:invalid_query, errors: validation.errors) if validation.error?
        end
      end

      RequestCookies = Data.define(:schema) do
        def call(parsed_values)
          validation = schema.validate(parsed_values[:cookies])
          Failure.fail!(:invalid_cookie, errors: validation.errors) if validation.error?
        end
      end

      VALIDATORS = {
        path_schema: Path,
        query_schema: Query,
        header_schema: RequestHeaders,
        cookie_schema: RequestCookies
      }.freeze

      def self.for(request_definition, openapi_version:, hooks: {})
        after_property_validation = hooks[:after_request_parameter_property_validation]
        VALIDATORS.filter_map do |key, klass|
          schema = request_definition.send(key)
          klass.new(Schema.new(schema, after_property_validation:, openapi_version:)) if schema
        end
      end
    end
  end
end

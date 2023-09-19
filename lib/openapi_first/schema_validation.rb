# frozen_string_literal: true

require 'json_schemer'

module OpenapiFirst
  class SchemaValidation
    attr_reader :raw_schema

    SCHEMAS = {
      '3.1' => 'https://spec.openapis.org/oas/3.1/dialect/base',
      '3.0' => 'json-schemer://openapi30/schema'
    }.freeze

    def initialize(schema, openapi_version:, write: true)
      @raw_schema = schema
      @schemer = JSONSchemer.schema(
        schema,
        access_mode: write ? 'write' : 'read',
        meta_schema: SCHEMAS.fetch(openapi_version),
        insert_property_defaults: true,
        before_property_validation: method(:before_property_validation)
      )
    end

    def validate(input)
      @schemer.validate(input)
    end

    private

    def before_property_validation(data, property, property_schema, parent)
      binary_format(data, property, property_schema, parent)
    end

    def binary_format(data, property, property_schema, _parent)
      return unless property_schema.is_a?(Hash) && property_schema['format'] == 'binary'

      data[property] = data[property][:tempfile].read
    end
  end
end

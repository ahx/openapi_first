# frozen_string_literal: true

require 'json_schemer'

module OpenapiFirst
  # Wraps JSONSchemer, mostly to add raw_schema method to test things :|
  class SchemaValidation
    attr_reader :raw_schema

    def initialize(schema, write: true)
      @raw_schema = schema
      @schemer = JSONSchemer.schema(
        schema,
        before_property_validation: write ? SKIP_READ_ONLY : nil
      )
    end

    def validate(input)
      @schemer.validate(input)
    end

    SKIP_READ_ONLY = lambda do |data, property, property_schema, schema|
      return unless property_schema['readOnly']

      schema['required']&.delete(property)
      data.delete(property) if data.key?(property) && property_schema.is_a?(Hash)
    end
    private_constant :SKIP_READ_ONLY
  end
end

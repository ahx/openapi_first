# frozen_string_literal: true

require 'json_schemer'

module OpenapiFirst
  # Wraps JSONSchemer, mostly to add raw_schema method to test things :|
  class SchemaValidation
    attr_reader :raw_schema

    def initialize(schema, write: true)
      @raw_schema = schema
      before_validation_hooks = []
      before_validation_hooks << SKIP_READ_ONLY if write
      before_validation_hooks << RAISE_WRITE_ONLY unless write
      @schemer = JSONSchemer.schema(
        schema,
        before_property_validation: before_validation_hooks
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

    RAISE_WRITE_ONLY = lambda do |data, property, property_schema, schema|
      if property_schema['writeOnly']
        schema['required']&.delete(property)
        if data.key?(property)
          message = "write-only field '#{property}' appears in response body!"
          raise OpenapiFirst::ResponseBodyInvalidError, message
        end
      end
    end
    private_constant :RAISE_WRITE_ONLY
  end
end

# frozen_string_literal: true

require 'json_schemer'

module OpenapiFirst
  class SchemaValidation
    attr_reader :raw_schema

    def initialize(schema, write: true)
      @raw_schema = schema
      custom_keywords = {}
      custom_keywords['writeOnly'] = method(:fail_if_truthy) unless write
      custom_keywords['readOnly'] = method(:fail_if_truthy) if write
      @schemer = JSONSchemer.schema(
        schema,
        keywords: custom_keywords,
        insert_property_defaults: true,
        before_property_validation: method(:before_property_validation)
      )
    end

    def validate(input)
      @schemer.validate(input)
    end

    private

    def fail_if_truthy(data, _curr_schema, _pointer)
      !data
    end

    def before_property_validation(data, property, property_schema, parent)
      convert_nullable(data, property, property_schema, parent)
      binary_format(data, property, property_schema, parent)
    end

    def binary_format(data, property, property_schema, _parent)
      return unless property_schema.is_a?(Hash) && property_schema['format'] == 'binary'

      property_schema['type'] = 'object'
      property_schema.delete('format')
      data[property].transform_keys!(&:to_s)
    end

    def convert_nullable(_data, _property, property_schema, _parent)
      return unless property_schema.is_a?(Hash) && property_schema['nullable'] && property_schema['type']

      property_schema['type'] = [*property_schema['type'], 'null']
      property_schema.delete('nullable')
    end
  end
end

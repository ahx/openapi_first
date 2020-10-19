# frozen_string_literal: true

require 'json_schemer'

module OpenapiFirst
  class SchemaValidation
    attr_reader :raw_schema

    def initialize(schema, write: true)
      @raw_schema = schema
      custom_keywords = {}
      custom_keywords['writeOnly'] = proc { |data| !data } unless write
      custom_keywords['readOnly'] = proc { |data| !data } if write
      @schemer = JSONSchemer.schema(
        schema,
        keywords: custom_keywords,
        before_property_validation: proc do |data, property, property_schema, parent|
          convert_nullable(data, property, property_schema, parent)
        end
      )
    end

    def validate(input)
      @schemer.validate(input)
    end

    private

    def convert_nullable(_data, _property, property_schema, _parent)
      return unless property_schema.is_a?(Hash) && property_schema['nullable'] && property_schema['type']

      property_schema['type'] = [*property_schema['type'], 'null']
      property_schema.delete('nullable')
    end
  end
end

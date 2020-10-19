# frozen_string_literal: true

require 'json_schemer'

module OpenapiFirst
  # Wraps JSONSchemer, mostly to add raw_schema method to test things :|
  class SchemaValidation
    attr_reader :raw_schema

    def initialize(schema, write: true)
      @raw_schema = schema
      custom_keywords = {}
      custom_keywords['writeOnly'] = proc { |data| !data } unless write
      custom_keywords['readOnly'] = proc { |data| !data } if write
      @schemer = JSONSchemer.schema(
        schema,
        keywords: custom_keywords
      )
    end

    def validate(input)
      @schemer.validate(input)
    end
  end
end

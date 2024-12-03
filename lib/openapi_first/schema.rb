# frozen_string_literal: true

require 'json_schemer'
require_relative 'schema/validation_result'

module OpenapiFirst
  # Validate data via JSON Schema. A wrapper around JSONSchemer.
  class Schema
    attr_reader :schema

    SCHEMAS = {
      '3.1' => 'https://spec.openapis.org/oas/3.1/dialect/base',
      '3.0' => 'json-schemer://openapi30/schema'
    }.freeze

    def initialize(schema, openapi_version: '3.1', write: true, after_property_validation: nil)
      @schemer = JSONSchemer.schema(
        schema,
        access_mode: write ? 'write' : 'read',
        meta_schema: SCHEMAS.fetch(openapi_version),
        insert_property_defaults: true,
        output_format: 'classic',
        after_property_validation:
      )
    end

    def validate(data)
      ValidationResult.new(@schemer.validate(data))
    end
  end
end

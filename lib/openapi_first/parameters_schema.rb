# frozen_string_literal: true

module OpenapiFirst
  # Builds a Schema instance from multiple parameter definitions
  module ParametersSchema
    def self.for(parameters)
      return unless parameters

      properties = {}
      required = []
      parameters.each do |parameter|
        schema = parameter['schema']
        name = parameter['name']
        properties[name] = schema if schema
        required << name if parameter['required']
      end

      schema_hash = {
        'properties' => properties,
        'required' => required
      }
      Schema.new(schema_hash)
    end
  end
end

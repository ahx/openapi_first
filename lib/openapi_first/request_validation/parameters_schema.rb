# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module ParametersSchema
      module_function

      # Takes a list of OpenAPI parameter definitions and returns a JSON Schema Hash
      def build(parameters)
        return unless parameters

        properties = {}
        required = []
        parameters.each do |parameter|
          schema = parameter['schema']
          name = parameter['name']
          properties[name] = schema if schema
          required << name if parameter['required']
        end

        {
          'properties' => properties,
          'required' => required
        }
      end
    end
  end
end

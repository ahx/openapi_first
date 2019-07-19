# frozen_string_literal: true

module OpenapiFirst
  class QueryParameterSchemas
    def initialize(allow_additional_parameters:)
      @additional_properties = allow_additional_parameters
    end

    def find(operation)
      build_parameter_schema(operation)
    end

    private

    def build_parameter_schema(operation)
      return unless operation&.query_parameters&.any?

      operation.query_parameters.each_with_object(
        'type' => 'object',
        'required' => [],
        'additionalProperties' => @additional_properties,
        'properties' => {}
      ) do |parameter, schema|
        schema['required'] << parameter.name if parameter.required
        schema['properties'][parameter.name] = parameter.schema
      end
    end
  end
end

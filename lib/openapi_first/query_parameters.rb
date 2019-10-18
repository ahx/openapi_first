# frozen_string_literal: true

module OpenapiFirst
  class QueryParameters
    def initialize(operation:, allow_additional_parameters:)
      @operation = operation
      @additional_properties = allow_additional_parameters
    end

    def to_json_schema
      return unless @operation&.query_parameters&.any?

      @operation.query_parameters.each_with_object(
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

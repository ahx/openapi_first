# frozen_string_literal: true

require 'openapi_parameters/parameter'
require_relative 'schema_validation'

module OpenapiFirst
  # This class is basically a cache for JSON Schemas of parameters
  class OperationSchemas
    # @operation [OpenapiFirst::Operation]
    def initialize(operation)
      @operation = operation
    end

    attr_reader :operation

    # Return JSON Schema of for all query parameters
    def query_parameters_schema
      @query_parameters_schema ||= build_json_schema(operation.query_parameters)
    end

    # Return JSON Schema of for all path parameters
    def path_parameters_schema
      @path_parameters_schema ||= build_json_schema(operation.path_parameters)
    end

    def header_parameters_schema
      @header_parameters_schema ||= build_json_schema(operation.header_parameters)
    end

    private

    # Build JSON Schema for given parameter definitions
    # @parameter_defs [Array<Hash>] Parameter definitions
    def build_json_schema(parameter_defs)
      init_schema = {
        'type' => 'object',
        'properties' => {},
        'required' => []
      }
      SchemaValidation.new(
        parameter_defs.each_with_object(init_schema) do |parameter_def, schema|
          parameter = OpenapiParameters::Parameter.new(parameter_def)
          schema['properties'][parameter.name] = parameter.schema if parameter.schema
          schema['required'] << parameter.name if parameter.required?
        end
      )
    end
  end
end

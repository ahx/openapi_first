# frozen_string_literal: true

require 'forwardable'
require_relative 'schema'

module OpenapiFirst
  class Parameters
    extend Forwardable

    def initialize(parameter_definitions, openapi_version:)
      @parameter_definitions = parameter_definitions
      @openapi_version = openapi_version
    end

    def_delegators :parameters, :map

    def empty?
      @parameter_definitions.empty?
    end

    def schema
      @schema ||= build_schema
    end

    def parameters
      @parameter_definitions.map do |parameter_object|
        OpenapiParameters::Parameter.new(parameter_object)
      end
    end

    private

    def build_schema
      init_schema = {
        'type' => 'object',
        'properties' => {},
        'required' => []
      }
      schema = @parameter_definitions.each_with_object(init_schema) do |parameter_def, result|
        parameter = OpenapiParameters::Parameter.new(parameter_def)
        result['properties'][parameter.name] = parameter.schema if parameter.schema
        result['required'] << parameter.name if parameter.required?
      end
      Schema.new(schema, openapi_version: @openapi_version)
    end
  end
end

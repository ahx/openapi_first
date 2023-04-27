# frozen_string_literal: true

require 'openapi_parameters'

module OpenapiFirst
  module Validators
    module ParametersValidator
      class << self
        def call(parameter_defs, unpacked_params)
          return unless parameter_defs&.any?

          json_schema = build_json_schema(parameter_defs)
          errors = SchemaValidation.new(json_schema).validate(unpacked_params)
          ErrorResponse.throw_error(400, serialize_parameter_errors(errors)) if errors.any?
        end

        private

        def build_json_schema(parameter_defs)
          init_schema = {
            'type' => 'object',
            'properties' => {},
            'required' => []
          }
          parameter_defs.each_with_object(init_schema) do |parameter_def, schema|
            parameter = OpenapiParameters::Parameter.new(parameter_def)
            schema['properties'][parameter.name] = parameter.schema if parameter.schema
            schema['required'] << parameter.name if parameter.required?
          end
        end

        def serialize_parameter_errors(validation_errors)
          validation_errors.map do |error|
            pointer = error['data_pointer'][1..].to_s
            {
              source: { parameter: pointer }
            }.update(ValidationFormat.error_details(error))
          end
        end
      end
    end
  end
end

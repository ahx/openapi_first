# frozen_string_literal: true

require 'openapi_parameters'

module OpenapiFirst
  module Validators
    module ParametersValidator
      class << self
        def call(json_schema, unpacked_params)
          return if json_schema.empty?

          errors = SchemaValidation.new(json_schema).validate(unpacked_params)
          ErrorResponse.throw_error(400, serialize_parameter_errors(errors)) if errors.any?
        end

        private

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

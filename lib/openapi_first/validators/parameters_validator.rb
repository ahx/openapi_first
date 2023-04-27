# frozen_string_literal: true

require 'openapi_parameters'

module OpenapiFirst
  module Validators
    module ParametersValidator
      class << self
        def call(schema_validation, unpacked_params)
          errors = schema_validation.validate(unpacked_params)
          ErrorResponse.throw_error(400, serialize_parameter_errors(errors)) if errors.any?
        end

        private

        def serialize_parameter_errors(validation_errors)
          validation_errors.map do |error|
            pointer = error['data_pointer'][1..].to_s
            {
              source: { parameter: pointer }
            }.update(ErrorFormat.error_details(error))
          end
        end
      end
    end
  end
end

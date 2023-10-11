# frozen_string_literal: true

require 'openapi_parameters'

module OpenapiFirst
  module Validators
    class ParametersValidator
      def initialize(location, schema_validation)
        @schema_validation = schema_validation
        @location = location
      end

      def call(unpacked_params)
        validation_result = @schema_validation.validate(unpacked_params)
        OpenapiFirst.error!(400, @location, validation_result:) if validation_result.error?
      end
    end
  end
end

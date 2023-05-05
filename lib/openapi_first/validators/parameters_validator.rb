# frozen_string_literal: true

require 'openapi_parameters'

module OpenapiFirst
  module Validators
    class ParametersValidator
      def initialize(schema_validation)
        @schema_validation = schema_validation
      end

      def call(unpacked_params)
        errors = @schema_validation.validate(unpacked_params)
        ErrorResponse.throw_error(400, serialize_validation_errors(errors)) if errors.any?
      end

      def source_name
        :parameter
      end

      private

      def serialize_validation_errors(validation_errors)
        validation_errors.map do |error|
          name = error['data_pointer'][1..].to_s
          {
            source: { source_name => name }
          }.update(ErrorFormat.error_details(error))
        end
      end
    end
  end
end

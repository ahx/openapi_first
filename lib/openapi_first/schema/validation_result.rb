# frozen_string_literal: true

require_relative 'validation_error'

module OpenapiFirst
  class Schema
    # Result of validating data against a schema. Return value of Schema#validate.
    class ValidationResult
      def initialize(validation)
        @validation = validation
      end

      def error? = @validation.any?

      # Returns an array of ValidationError objects.
      def errors
        @errors ||= @validation.map do |err|
          ValidationError.new(
            message: err['error'],
            data_pointer: err['data_pointer'],
            schema_pointer: err['schema_pointer'],
            type: err['type'],
            details: err['details']
          )
        end
      end
    end
  end
end

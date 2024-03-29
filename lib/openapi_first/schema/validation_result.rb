# frozen_string_literal: true

require_relative 'validation_error'

module OpenapiFirst
  class Schema
    # Result of validating data against a schema. Return value of Schema#validate.
    class ValidationResult
      def initialize(validation, schema:, data:)
        @validation = validation
        @schema = schema
        @data = data
      end

      attr_reader :schema, :data

      def error? = @validation.any?

      # Returns an array of ValidationError objects.
      def errors
        @errors ||= @validation.map do |err|
          ValidationError.new(err)
        end
      end
    end
  end
end

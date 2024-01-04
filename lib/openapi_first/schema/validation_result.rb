# frozen_string_literal: true

require_relative 'validation_error'

module OpenapiFirst
  class Schema
    class ValidationResult
      def initialize(validation, schema:, data:)
        @validation = validation
        @schema = schema
        @data = data
      end

      attr_reader :schema, :data

      def error? = @validation.any?

      def errors
        @errors ||= @validation.map do |err|
          ValidationError.new(err)
        end
      end

      # Returns a message that is used in exception messages.
      def message
        return unless error?

        errors.map(&:error).join('. ')
      end
    end
  end
end

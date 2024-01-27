# frozen_string_literal: true

module OpenapiFirst
  class Schema
    # One of multiple validation errors. Returned by Schema::ValidationResult#errors.
    class ValidationError
      def initialize(json_schemer_error)
        @error = json_schemer_error
      end

      def error = @error['error']
      def schemer_error = @error
      def instance_location = @error['data_pointer']
      def schema_location = @error['schema_pointer']
      def type = @error['type']
      def details = @error['details']
    end
  end
end

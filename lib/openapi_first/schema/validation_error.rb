# frozen_string_literal: true

module OpenapiFirst
  class Schema
    # One of multiple validation errors. Returned by Schema::ValidationResult#errors.
    ValidationError = Data.define(:value, :message, :data_pointer, :schema_pointer, :type, :details, :schema) do
      # @deprecated Please use {#message} instead
      def error
        warn 'OpenapiFirst::Schema::ValidationError#error is deprecated. Use #message instead.'
        message
      end

      # @deprecated Please use {#data_pointer} instead
      def instance_location
        warn 'OpenapiFirst::Schema::ValidationError#instance_location is deprecated. Use #data_pointer instead.'
        data_pointer
      end

      # @deprecated Please use {#schema_pointer} instead
      def schema_location
        warn 'OpenapiFirst::Schema::ValidationError#schema_location is deprecated. Use #schema_pointer instead.'
        schema_pointer
      end
    end
  end
end

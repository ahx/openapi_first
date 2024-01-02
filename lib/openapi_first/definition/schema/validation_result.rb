# frozen_string_literal: true

module OpenapiFirst
  class Schema
    ValidationResult = Struct.new(:output, :schema, :data, keyword_init: true) do
      def error? = !output['valid']

      # Returns a message that is used in exception messages.
      def message
        return unless error?

        (output['errors']&.map { |e| e['error'] }&.join('. ') || output['error'])
      end
    end
  end
end

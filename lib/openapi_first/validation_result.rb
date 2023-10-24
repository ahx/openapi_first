# frozen_string_literal: true

module OpenapiFirst
  ValidationResult = Struct.new(:result, :schema, :data, keyword_init: true) do
    def valid? = result['valid']
    def error? = !result['valid']

    # Returns a message that is used in exception messages.
    def message
      return if valid?

      (result['errors']&.map { |e| e['error'] }&.join('. ') || result['error'])&.concat('.')
    end
  end
end

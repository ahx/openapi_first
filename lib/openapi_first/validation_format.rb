# frozen_string_literal: true

module OpenapiFirst
  module ValidationFormat
    SIMPLE_TYPES = %w[string integer].freeze

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def self.error_details(error)
      if error['type'] == 'pattern'
        {
          title: 'is not valid',
          detail: "does not match pattern '#{error['schema']['pattern']}'"
        }
      elsif error['type'] == 'format'
        {
          title: "has not a valid #{error.dig('schema', 'format')} format",
          detail: "#{error['data'].inspect} is not a valid #{error.dig('schema', 'format')} format"
        }
      elsif error['type'] == 'required'
        missing_keys = error['details']['missing_keys']
        {
          title: "is missing required properties: #{missing_keys.join(', ')}"
        }
      elsif error['type'] == 'readOnly'
        {
          title: 'appears in request, but is read-only'
        }
      elsif error['type'] == 'writeOnly'
        {
          title: 'write-only field appears in response:'
        }
      elsif SIMPLE_TYPES.include?(error['type'])
        {
          title: "should be a #{error['type']}"
        }
      elsif error['schema'] == false
        { title: 'unknown fields are not allowed' }
      else
        { title: "is not valid: #{error['data'].inspect}" }
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end
end

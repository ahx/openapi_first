# frozen_string_literal: true

module OpenapiFirst
  module ValidationFormat
    SIMPLE_TYPES = %w[string integer].freeze

    # rubocop:disable Metrics/MethodLength
    def self.error_details(error)
      if error['type'] == 'pattern'
        {
          title: 'is not valid',
          detail: "does not match pattern '#{error['schema']['pattern']}'"
        }
      elsif error['type'] == 'required'
        missing_keys = error['details']['missing_keys']
        {
          title: "is missing required properties: #{missing_keys.join(', ')}"
        }
      elsif SIMPLE_TYPES.include?(error['type'])
        {
          title: "should be a #{error['type']}"
        }
      elsif error['schema'] == false
        { title: 'unknown fields are not allowed' }
      else
        { title: 'is not valid' }
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end

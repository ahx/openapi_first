# frozen_string_literal: true

module OpenapiFirst
  # @visibility private
  module ResponseBodyParsers
    DEFAULT = ->(body) { body }

    @parsers = {}

    class << self
      attr_reader :parsers

      def register(pattern, parser)
        parsers[pattern] = parser
      end

      def [](content_type)
        key = parsers.keys.find { content_type&.match?(_1) }
        parsers.fetch(key) { DEFAULT }
      end
    end

    register(/json/i, lambda do |body|
      JSON.parse(body)
    rescue JSON::ParserError
      Failure.fail!(:invalid_response_body, message: 'Response body is invalid: Failed to parse response body as JSON')
    end)
  end
end

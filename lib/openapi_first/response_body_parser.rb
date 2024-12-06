# frozen_string_literal: true

module OpenapiFirst
  # @visibility private
  module ResponseBodyParser
    def self.[](content_type)
      return JSON if content_type.to_s.match?(/json/i)

      Default
    end

    JSON = lambda do |body|
      ::JSON.parse(body)
    rescue ::JSON::ParserError
      Failure.fail!(:invalid_response_body, message: 'Response body is invalid: Failed to parse response body as JSON')
    end

    Default = lambda do |body|
      body
    end
  end
end

# frozen_string_literal: true

require_relative 'parameters'
require_relative 'response_body_parsers'

module OpenapiFirst
  ParsedResponse = Data.define(:body, :headers)

  # Parse a response
  class ResponseParser
    def initialize(headers:, content_type:)
      @headers_parser = build_headers_parser(headers)
      @body_parser = ResponseBodyParsers[content_type]
    end

    def parse(rack_response)
      body = @body_parser.call(read_body(rack_response))
      return [nil, body] if body.is_a?(Failure)

      [ParsedResponse.new(
        body:,
        headers: @headers_parser&.unpack(rack_response.headers) || {}
      ), nil]
    end

    private

    def read_body(rack_response)
      buffered_body = +''

      if rack_response.body.respond_to?(:each)
        rack_response.body.each { |chunk| buffered_body << chunk }
        return buffered_body
      end
      rack_response.body
    rescue TypeError
      raise Error, "Cannot not read response body. Response is not string-like, but is a #{rack_response.body.class}."
    end

    def build_headers_parser(headers)
      return unless headers&.any?

      Parameters::Parser.new(
        headers.map do |header|
          Parameters::Parameter.new(
            { 'name' => header.name, 'in' => 'header' },
            schema: header.resolved_schema
          )
        end
      )
    end
  end
end

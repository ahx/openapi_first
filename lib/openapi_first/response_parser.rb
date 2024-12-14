# frozen_string_literal: true

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
      ParsedResponse.new(
        body: @body_parser.call(read_body(rack_response)),
        headers: @headers_parser.call(rack_response.headers)
      )
    end

    private

    def read_body(rack_response)
      buffered_body = +''
      if rack_response.body.respond_to?(:each)
        rack_response.body.each { |chunk| buffered_body.to_s << chunk }
        return buffered_body
      end
      rack_response.body
    end

    def build_headers_parser(header_definitions)
      headers_as_parameters = header_definitions.to_a.map do |name, definition|
        definition.merge('name' => name, 'in' => 'header')
      end
      OpenapiParameters::Header.new(headers_as_parameters).method(:unpack)
    end
  end
end

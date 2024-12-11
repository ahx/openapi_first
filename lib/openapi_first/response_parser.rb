# frozen_string_literal: true

require_relative 'response_body_parser'

module OpenapiFirst
  ParsedResponse = Data.define(:body, :headers)

  # Parse a response
  class ResponseParser
    def initialize(headers:, content_type:)
      @headers = headers
      @body_parser = ResponseBodyParser[content_type]
    end

    def parse(rack_response)
      body = read_body(rack_response)
      ParsedResponse.new(
        body: @body_parser.call(body),
        headers: parse_headers(rack_response)
      )
    end

    private

    attr_reader :headers

    def read_body(rack_response)
      buffered_body = +''
      if rack_response.body.respond_to?(:each)
        rack_response.body.each { |chunk| buffered_body.to_s << chunk }
        return buffered_body
      end
      rack_response.body
    end

    def parse_headers(rack_response)
      return {} if headers.nil?

      # TODO: memoize unpacker
      headers_as_parameters = headers.map do |name, definition|
        definition.merge('name' => name, 'in' => 'header')
      end
      OpenapiParameters::Header.new(headers_as_parameters).unpack(rack_response.headers)
    end
  end
end

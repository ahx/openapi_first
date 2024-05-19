# frozen_string_literal: true

module OpenapiFirst
  ParsedResponse = Data.define(:body, :headers)

  class ResponseParser
    def initialize(response_definition)
      @response_definition = response_definition
    end

    attr_reader :response_definition

    def parse(rack_response)
      ParsedResponse.new(
        body: parse_body(rack_response),
        headers: parse_headers(rack_response)
      )
    end

    private

    def parse_body(rack_response)
      MultiJson.load(read_body(rack_response)) if /json/i.match?(@response_definition.content_type)
    rescue MultiJson::ParseError
      raise ResponseInvalidError, 'Response body is invalid: Failed to parse response body as JSON'
    end

    def read_body(rack_response)
      buffered_body = +''
      if rack_response.body.respond_to?(:each)
        rack_response.body.each { |chunk| buffered_body.to_s << chunk }
        return buffered_body
      end
      rack_response.body
    end

    def parse_headers(rack_response)
      return {} if response_definition&.headers.nil?

      # TODO: memoize unpacker
      headers_as_parameters = response_definition.headers.map do |name, definition|
        definition.merge('name' => name, 'in' => 'header')
      end
      OpenapiParameters::Header.new(headers_as_parameters).unpack(rack_response.headers)
    end
  end
end

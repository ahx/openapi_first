# frozen_string_literal: true

require 'multi_json'

module OpenapiFirst
  class BodyParser
    class ParsingError < StandardError; end

    def parse(request, content_type)
      body = read_body(request)
      return if body.empty?

      return MultiJson.load(body) if content_type =~ (/json/i) && (content_type =~ /json/i)
      return request.POST if request.form_data?

      body
    rescue MultiJson::ParseError
      raise ParsingError, 'Failed to parse body as application/json'
    end

    private

    def read_body(request)
      body = request.body.read
      request.body.rewind
      body
    end
  end
end

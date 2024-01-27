# frozen_string_literal: true

require 'multi_json'

module OpenapiFirst
  class BodyParser # :nodoc:
    def self.const_missing(const_name)
      super unless const_name == :ParsingError
      warn 'DEPRECATION WARNING: OpenapiFirst::BodyParser::ParsingError is deprecated. ' \
           'Use OpenapiFirst::ParseError instead.'
      OpenapiFirst::ParseError
    end

    def parse(request, content_type)
      body = read_body(request)
      return if body.empty?

      return MultiJson.load(body) if content_type =~ (/json/i) && (content_type =~ /json/i)
      return request.POST if request.form_data?

      body
    rescue MultiJson::ParseError
      raise ParseError, 'Failed to parse body as JSON'
    end

    private

    def read_body(request)
      body = request.body.read
      request.body.rewind
      body
    end
  end
end

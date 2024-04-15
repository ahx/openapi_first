# frozen_string_literal: true

require 'multi_json'

module OpenapiFirst
  # @!visibility private
  class BodyParser
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

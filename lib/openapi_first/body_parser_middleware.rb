# frozen_string_literal: true

require 'multi_json'

module OpenapiFirst
  class BodyParserMiddleware
    def initialize(app)
      @app = app
    end

    ROUTER_PARSED_BODY = 'router.parsed_body'
    private_constant :ROUTER_PARSED_BODY

    def call(env)
      env[ROUTER_PARSED_BODY] = parse_body(env)
      @app.call(env)
    end

    private

    def parse_body(env)
      request = Rack::Request.new(env)
      body = read_body(request)
      return if body.empty?

      return MultiJson.load(body) if request.media_type =~ (/json/i) && (request.media_type =~ /json/i)
      return request.POST if request.form_data?

      body
    rescue MultiJson::ParseError
      raise BodyParsingError, 'Failed to parse body as application/json'
    end

    def read_body(request)
      body = request.body.read
      request.body.rewind
      body
    end
  end
end

# frozen_string_literal: true

module OpenapiFirst
  class BodyParserMiddleware
    def initialize(app, options = {})
      @raise = options.fetch(:raise_error, false)
      parsers = :json
      @parser = Hanami::Middleware::BodyParser.new(app, parsers)
    end

    def call(env)
      @parser.call(env)
    rescue Hanami::Middleware::BodyParser::BodyParsingError => e
      err = { title: 'Failed to parse body as JSON', status: '400' }
      err[:detail] = e.cause unless ENV['RACK_ENV'] == 'production'
      errors = [err]
      raise RequestInvalidError, errors if @raise

      Rack::Response.new(
        MultiJson.dump(errors: errors),
        400,
        Rack::CONTENT_TYPE => 'application/vnd.api+json'
      ).finish
    end
  end
end

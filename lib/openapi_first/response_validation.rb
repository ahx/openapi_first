# frozen_string_literal: true

require_relative 'response_validator'

module OpenapiFirst
  class ResponseValidation
    def initialize(app)
      @app = app
    end

    def call(env)
      operation = env[OPERATION]
      return [500, {}, '']if operation.nil?

      validator =
        status, headers, body = @app.call(env)
        halt(500) unless operation.content_type_for(status)
        [status, headers, body]
      end
    end

    private

    def halt(status, body='')
      throw :halt, [status, {}, body]
    end

    def error_response(status, error)
      Rack::Response.new(
        MultiJson.dump(errors: errors),
        status,
        Rack::CONTENT_TYPE => 'application/vnd.api+json'
      ).finish
    end
  end
end

# frozen_string_literal: true

require_relative 'observe'

module OpenapiFirst
  module Test
    REQUEST = 'openapi.test.request'
    RESPONSE = 'openapi.test.response'

    # A wrapper of the original app
    # with silent request/response validation to track requests/responses.
    class App < SimpleDelegator
      def initialize(app, api:, validate_request_after_handling:)
        super(app)
        @app = app
        @definition = Test[api]
        @validate_request_after_handling = validate_request_after_handling
      end

      def call(env)
        request = Rack::Request.new(env)
        unless @validate_request_after_handling
          env[Test::REQUEST] = @definition.validate_request(request, raise_error: false)
        end

        response = @app.call(env)
        if @validate_request_after_handling
          env[Test::REQUEST] = @definition.validate_request(request, raise_error: false)
        end

        status, headers, body = response
        env[Test::RESPONSE] =
          @definition.validate_response(request, Rack::Response[status, headers, body], raise_error: false)
        response
      end
    end
  end
end

# frozen_string_literal: true

require 'rack'
module OpenapiFirst
  module Middlewares
    # A Rack middleware to validate requests against an OpenAPI API description
    class ResponseValidation
      # @param app The parent Rack application
      # @param options Hash
      #   :spec    Path to the OpenAPI file or an instance of Definition
      def initialize(app, options = {})
        @app = app

        spec = options.fetch(:spec)
        raise "You have to pass spec: when initializing #{self.class}" unless spec

        @definition = spec.is_a?(Definition) ? spec : OpenapiFirst.load(spec)
      end

      def call(env)
        request = find_request(env)
        response = @app.call(env)
        request.response(response).validate!

        response
      end

      private

      def find_request(env)
        env[REQUEST] ||= @definition.request(Rack::Request.new(env))
      end
    end
  end
end

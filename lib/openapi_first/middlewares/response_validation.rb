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

      # @attr_reader [Proc] app The upstream Rack application
      attr_reader :app

      def call(env)
        status, headers, body = @app.call(env)
        body = read_body(body)
        @definition.validate_response(Rack::Request.new(env), Rack::Response[status, headers, body], raise_error: true)
        [status, headers, body]
      end

      private

      def read_body(body)
        return body.to_ary if body.respond_to?(:to_ary)

        result = []
        body.each { |part| result << part }
        result
      end
    end
  end
end

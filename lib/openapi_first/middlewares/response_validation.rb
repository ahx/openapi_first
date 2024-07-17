# frozen_string_literal: true

require 'rack'

module OpenapiFirst
  module Middlewares
    # A Rack middleware to validate requests against an OpenAPI API description
    class ResponseValidation
      # @param app The parent Rack application
      # @param options Hash
      #   :spec [String, OpenapiFirst::Definition] Path to the OpenAPI file or an instance of Definition
      #   :raise_error [Boolean] Whether to raise an error if validation fails. default: true
      def initialize(app, options = {})
        @app = app
        @raise = options.fetch(:raise_error, OpenapiFirst.configuration.response_validation_raise_error)

        spec = options.fetch(:spec)
        raise "You have to pass spec: when initializing #{self.class}" unless spec

        @definition = spec.is_a?(Definition) ? spec : OpenapiFirst.load(spec)
      end

      # @attr_reader [Proc] app The upstream Rack application
      attr_reader :app

      def call(env)
        status, headers, body = @app.call(env)
        @definition.validate_response(Rack::Request.new(env), Rack::Response[status, headers, body], raise_error: @raise)
        [status, headers, body]
      end
    end
  end
end

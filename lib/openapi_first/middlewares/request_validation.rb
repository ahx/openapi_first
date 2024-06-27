# frozen_string_literal: true

require 'rack'
module OpenapiFirst
  module Middlewares
    # A Rack middleware to validate requests against an OpenAPI API description
    class RequestValidation
      # @param app The parent Rack application
      # @param options An optional Hash of configuration options to override defaults
      #   :raise_error    A Boolean indicating whether to raise an error if validation fails.
      #                   default: false
      #   :error_response The Class to use for error responses.
      #                   This can be a Symbol-name of an registered error response (:default, :jsonapi)
      #                   or it can be set to false to disable returning a response.
      #                   default: OpenapiFirst::Plugins::Default::ErrorResponse (Config.default_options.error_response)
      def initialize(app, options = {})
        @app = app
        @raise = options.fetch(:raise_error, OpenapiFirst.configuration.request_validation_raise_error)
        @error_response_class = error_response_option(options[:error_response])

        spec = options.fetch(:spec)
        raise "You have to pass spec: when initializing #{self.class}" unless spec

        @definition = spec.is_a?(Definition) ? spec : OpenapiFirst.load(spec)
      end

      # @attr_reader [Proc] app The upstream Rack application
      attr_reader :app

      def call(env)
        validated = @definition.validate_request(Rack::Request.new(env), raise_error: @raise)
        env[REQUEST] = validated
        failure = validated.error
        return @error_response_class.new(failure:).render if failure && @error_response_class

        @app.call(env)
      end

      private

      def error_response_option(value)
        return if value == false
        return OpenapiFirst.find_error_response(value) if value.is_a?(Symbol)

        value || OpenapiFirst.configuration.request_validation_error_response
      end
    end
  end
end

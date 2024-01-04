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
      #                   default: OpenapiFirst::Plugins::Default::ErrorResponse (Config.default_options.error_response)
      def initialize(app, options = {})
        @app = app
        @raise = options.fetch(:raise_error, OpenapiFirst.configuration.request_validation_raise_error)
        @error_response_class = error_response(options[:error_response])

        spec = options.fetch(:spec)
        raise "You have to pass spec: when initializing #{self.class}" unless spec

        @definition = spec.is_a?(Definition) ? spec : OpenapiFirst.load(spec)
      end

      def call(env)
        request = find_request(env)
        return @app.call(env) unless request

        failure = if @raise
                    request.validate!
                  else
                    request.validate
                  end
        return @error_response_class.new(failure:).render if failure

        @app.call(env)
      end

      private

      def find_request(env)
        env[REQUEST] ||= @definition.request(Rack::Request.new(env))
      end

      def error_response(mod)
        return OpenapiFirst.plugin(mod)::ErrorResponse if mod.is_a?(Symbol)

        mod || OpenapiFirst.configuration.request_validation_error_response
      end
    end
  end
end

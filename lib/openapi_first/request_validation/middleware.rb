# frozen_string_literal: true

require 'rack'
require 'multi_json'
require_relative '../use_router'
require_relative 'request_body_validator'

module OpenapiFirst
  class RequestInvalidError < StandardError; end

  module RequestValidation
    # A Rack middleware to validate requests against an OpenAPI API description
    class Middleware
      prepend UseRouter

      # @param app The parent Rack application
      # @param options An optional Hash of configuration options to override defaults
      #   :error_response A Boolean indicating whether to raise an error if validation fails.
      #                   default: OpenapiFirst::Plugins::Default::ErrorResponse (Config.default_options.error_response)
      #   :raise_error    The Class to use for error responses.
      #                   default: false
      def initialize(app, options = {})
        @app = app
        @raise = options.fetch(:raise_error, OpenapiFirst.configuration.request_validation_raise_error)
        @error_response_class = error_response(options[:error_response])
      end

      def call(env)
        operation = env[OPERATION]
        return @app.call(env) unless operation

        error = validate_request(operation, env)
        if error
          raise RequestInvalidError, error.error_message if @raise

          return @error_response_class.new(env, error).render
        end

        @app.call(env)
      end

      private

      def error_response(mod)
        return OpenapiFirst.plugin(mod)::ErrorResponse if mod.is_a?(Symbol)

        mod || OpenapiFirst.configuration.error_response
      end

      def validate_request(operation, env)
        catch(FAIL) do
          env[PARAMS] = {}
          validate_parameters!(operation, env)
          validate_request_body!(operation, env)
          nil
        end
      end

      def validate_parameters!(operation, env)
        validate_query_params!(operation, env)
        validate_path_params!(operation, env)
        validate_cookie_params!(operation, env)
        validate_header_params!(operation, env)
      end

      def validate_path_params!(operation, env)
        parameters = operation.path_parameters
        return unless parameters

        unpacked_params = parameters.unpack(env)
        schema_validation = parameters.schema.validate(unpacked_params)
        RequestValidation.fail!(400, :path, schema_validation:) if schema_validation.error?
        env[PATH_PARAMS] = unpacked_params
        env[PARAMS].merge!(unpacked_params)
      end

      def validate_query_params!(operation, env)
        parameters = operation.query_parameters
        return unless parameters

        unpacked_params = parameters.unpack(env)
        schema_validation = parameters.schema.validate(unpacked_params)
        RequestValidation.fail!(400, :query, schema_validation:) if schema_validation.error?
        env[QUERY_PARAMS] = unpacked_params
        env[PARAMS].merge!(unpacked_params)
      end

      def validate_cookie_params!(operation, env)
        parameters = operation.cookie_parameters
        return unless parameters

        unpacked_params = parameters.unpack(env)
        schema_validation = parameters.schema.validate(unpacked_params)
        RequestValidation.fail!(400, :cookie, schema_validation:) if schema_validation.error?
        env[COOKIE_PARAMS] = unpacked_params
      end

      def validate_header_params!(operation, env)
        parameters = operation.header_parameters
        return unless parameters

        unpacked_params = parameters.unpack(env)
        schema_validation = parameters.schema.validate(unpacked_params)
        RequestValidation.fail!(400, :header, schema_validation:) if schema_validation.error?
        env[HEADER_PARAMS] = unpacked_params
      end

      def validate_request_body!(operation, env)
        env[REQUEST_BODY] = RequestBodyValidator.new(operation, env).validate!
      end
    end
  end
end

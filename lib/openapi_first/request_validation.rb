# frozen_string_literal: true

require 'rack'
require 'multi_json'
require_relative 'use_router'
require_relative 'error_response'
require_relative 'request_body_validator'
require_relative 'string_keyed_hash'
require_relative 'request_validation_error'
require 'openapi_parameters'

module OpenapiFirst
  class RequestValidation
    prepend UseRouter

    FAIL = :request_validation_failed
    private_constant :FAIL

    # @param status [Integer] The intended HTTP status code (usually 400)
    # @param location [Symbol] One of :body, :header, :cookie, :query, :path
    # @param schema_validation [OpenapiFirst::JsonSchema::Result]
    def self.fail!(status, location, schema_validation: nil)
      throw FAIL, RequestValidationError.new(
        status:,
        location:,
        schema_validation:
      )
    end

    def initialize(app, options = {})
      @app = app
      @raise = options.fetch(:raise_error, false)
      @error_response_class =
        Plugins.find_error_response(options.fetch(:error_response, Config.default_options.error_response))
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

    def validate_request(operation, env)
      catch(FAIL) do
        env[PARAMS] = {}
        validate_query_params!(operation, env)
        validate_path_params!(operation, env)
        validate_cookie_params!(operation, env)
        validate_header_params!(operation, env)
        validate_request_body!(operation, env)
        nil
      end
    end

    def validate_path_params!(operation, env)
      path_parameters = operation.path_parameters
      return if path_parameters.empty?

      hashy = StringKeyedHash.new(env[Router::RAW_PATH_PARAMS])
      unpacked_path_params = OpenapiParameters::Path.new(path_parameters).unpack(hashy)
      schema_validation = operation.path_parameters_schema.validate(unpacked_path_params)
      RequestValidation.fail!(400, :path, schema_validation:) if schema_validation.error?
      env[PATH_PARAMS] = unpacked_path_params
      env[PARAMS].merge!(unpacked_path_params)
    end

    def validate_query_params!(operation, env)
      query_parameters = operation.query_parameters
      return if operation.query_parameters.empty?

      unpacked_query_params = OpenapiParameters::Query.new(query_parameters).unpack(env['QUERY_STRING'])
      schema_validation = operation.query_parameters_schema.validate(unpacked_query_params)
      RequestValidation.fail!(400, :query, schema_validation:) if schema_validation.error?
      env[QUERY_PARAMS] = unpacked_query_params
      env[PARAMS].merge!(unpacked_query_params)
    end

    def validate_cookie_params!(operation, env)
      cookie_parameters = operation.cookie_parameters
      return unless cookie_parameters&.any?

      unpacked_params = OpenapiParameters::Cookie.new(cookie_parameters).unpack(env['HTTP_COOKIE'])
      schema_validation = operation.cookie_parameters_schema.validate(unpacked_params)
      RequestValidation.fail!(400, :cookie, schema_validation:) if schema_validation.error?
      env[COOKIE_PARAMS] = unpacked_params
    end

    def validate_header_params!(operation, env)
      header_parameters = operation.header_parameters
      return if header_parameters.empty?

      unpacked_header_params = OpenapiParameters::Header.new(header_parameters).unpack_env(env)
      schema_validation = operation.header_parameters_schema.validate(unpacked_header_params)
      RequestValidation.fail!(400, :header, schema_validation:) if schema_validation.error?
      env[HEADER_PARAMS] = unpacked_header_params
    end

    def validate_request_body!(operation, env)
      RequestBodyValidator.new(operation, env).validate! if operation.request_body
    end
  end
end

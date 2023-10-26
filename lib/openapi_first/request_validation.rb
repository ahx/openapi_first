# frozen_string_literal: true

require 'rack'
require 'multi_json'
require_relative 'use_router'
require_relative 'error_response'
require_relative 'request_body_validator'
require_relative 'string_keyed_hash'
require 'openapi_parameters'

module OpenapiFirst
  class RequestValidation
    prepend UseRouter

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
        location, title = error.values_at(:location, :title)
        raise RequestInvalidError, error_message(title, location) if @raise

        return error_response(error).render
      end
      @app.call(env)
    end

    private

    def error_message(title, location)
      return title unless location

      "#{TOPICS.fetch(location)} #{title}"
    end

    TOPICS = {
      request_body: 'Request body invalid:',
      query: 'Query parameter invalid:',
      header: 'Header parameter invalid:',
      path: 'Path segment invalid:',
      cookie: 'Cookie value invalid:'
    }.freeze
    private_constant :TOPICS

    def error_response(error_object)
      @error_response_class.new(**error_object)
    end

    def validate_request(operation, env)
      catch(:error) do
        env[PARAMS] = {}
        validate_query_params!(operation, env)
        validate_path_params!(operation, env)
        validate_cookie_params!(operation, env)
        validate_header_params!(operation, env)
        RequestBodyValidator.new(operation, env).validate! if operation.request_body
        nil
      end
    end

    def validate_path_params!(operation, env)
      path_parameters = operation.path_parameters
      return if path_parameters.empty?

      hashy = StringKeyedHash.new(env[Router::RAW_PATH_PARAMS])
      unpacked_path_params = OpenapiParameters::Path.new(path_parameters).unpack(hashy)
      validation_result = operation.path_parameters_schema.validate(unpacked_path_params)
      ErrorResponse.throw!(400, :path, validation_result:) if validation_result.error?
      env[PATH_PARAMS] = unpacked_path_params
      env[PARAMS].merge!(unpacked_path_params)
    end

    def validate_query_params!(operation, env)
      query_parameters = operation.query_parameters
      return if operation.query_parameters.empty?

      unpacked_query_params = OpenapiParameters::Query.new(query_parameters).unpack(env['QUERY_STRING'])
      validation_result = operation.query_parameters_schema.validate(unpacked_query_params)
      ErrorResponse.throw!(400, :query, validation_result:) if validation_result.error?
      env[QUERY_PARAMS] = unpacked_query_params
      env[PARAMS].merge!(unpacked_query_params)
    end

    def validate_cookie_params!(operation, env)
      cookie_parameters = operation.cookie_parameters
      return unless cookie_parameters&.any?

      unpacked_params = OpenapiParameters::Cookie.new(cookie_parameters).unpack(env['HTTP_COOKIE'])
      validation_result = operation.cookie_parameters_schema.validate(unpacked_params)
      ErrorResponse.throw!(400, :cookie, validation_result:) if validation_result.error?
      env[COOKIE_PARAMS] = unpacked_params
    end

    def validate_header_params!(operation, env)
      header_parameters = operation.header_parameters
      return if header_parameters.empty?

      unpacked_header_params = OpenapiParameters::Header.new(header_parameters).unpack_env(env)
      validation_result = operation.header_parameters_schema.validate(unpacked_header_params)
      ErrorResponse.throw!(400, :header, validation_result:) if validation_result.error?
      env[HEADER_PARAMS] = unpacked_header_params
    end
  end
end

# frozen_string_literal: true

require 'rack'
require 'multi_json'
require_relative 'inbox'
require_relative 'use_router'
require_relative 'validation_format'
require 'openapi_parameters'

module OpenapiFirst
  class RequestValidation # rubocop:disable Metrics/ClassLength
    prepend UseRouter

    def initialize(app, options = {})
      @app = app
      @raise = options.fetch(:raise_error, false)
    end

    def call(env) # rubocop:disable Metrics/AbcSize
      operation = env[OPERATION]
      return @app.call(env) unless operation

      env[INBOX] = env[PARAMETERS]
      error = catch(:error) do
        query_params = OpenapiParameters::Query.new(operation.query_parameters).unpack(env['QUERY_STRING'])
        validate_query_parameters!(operation, query_params)

        env[PARAMETERS].merge!(query_params)
        req = Rack::Request.new(env)
        return @app.call(env) unless operation.request_body

        validate_request_content_type!(operation, req.content_type)
        parsed_request_body = parse_and_validate_request_body!(operation, req)
        env[REQUEST_BODY] = parsed_request_body
        env[INBOX] = env[INBOX].merge parsed_request_body if parsed_request_body.is_a?(Hash)
        nil
      end
      if error
        raise RequestInvalidError, error[:errors] if @raise

        return validation_error_response(error[:status], error[:errors])
      end
      @app.call(env)
    end

    private

    ROUTER_PARSED_BODY = 'router.parsed_body'

    def parse_and_validate_request_body!(operation, request)
      env = request.env

      body = env.delete(ROUTER_PARSED_BODY) if env.key?(ROUTER_PARSED_BODY)

      validate_request_body_presence!(body, operation)
      return if body.nil?

      schema = operation&.request_body_schema(request.content_type)
      return unless schema

      errors = schema.validate(body)
      throw_error(400, serialize_request_body_errors(errors)) if errors.any?
      body
    end

    def validate_request_content_type!(operation, content_type)
      operation.valid_request_content_type?(content_type) || throw_error(415)
    end

    def validate_request_body_presence!(body, operation)
      return unless operation.request_body['required'] && body.nil?

      throw_error(415, 'Request body is required')
    end

    def default_error(status, title = Rack::Utils::HTTP_STATUS_CODES[status])
      {
        status: status.to_s,
        title: title
      }
    end

    def throw_error(status, errors = [default_error(status)])
      throw :error, {
        status: status,
        errors: errors
      }
    end

    def validation_error_response(status, errors)
      Rack::Response.new(
        MultiJson.dump(errors: errors),
        status,
        Rack::CONTENT_TYPE => 'application/vnd.api+json'
      ).finish
    end

    def serialize_request_body_errors(validation_errors)
      validation_errors.map do |error|
        {
          source: {
            pointer: error['data_pointer']
          }
        }.update(ValidationFormat.error_details(error))
      end
    end

    def build_json_schema(parameter_defs)
      init_schema = {
        'type' => 'object',
        'properties' => {},
        'required' => []
      }
      parameter_defs.each_with_object(init_schema) do |parameter_def, schema|
        parameter = OpenapiParameters::Parameter.new(parameter_def)
        schema['properties'][parameter.name] = parameter.schema if parameter.schema
        schema['required'] << parameter.name if parameter.required?
      end
    end

    def validate_query_parameters!(operation, params)
      parameter_defs = operation.query_parameters
      return unless parameter_defs&.any?

      json_schema = build_json_schema(parameter_defs)
      errors = SchemaValidation.new(json_schema).validate(params)
      throw_error(400, serialize_parameter_errors(errors)) if errors.any?
    end

    def serialize_parameter_errors(validation_errors)
      validation_errors.map do |error|
        pointer = error['data_pointer'][1..].to_s
        {
          source: { parameter: pointer }
        }.update(ValidationFormat.error_details(error))
      end
    end
  end
end

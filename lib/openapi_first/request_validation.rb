# frozen_string_literal: true

require 'rack'
require 'multi_json'
require_relative 'inbox'
require_relative 'use_router'
require_relative 'validation_format'

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

      env[INBOX] = {}
      error = catch(:error) do
        params = validate_query_parameters!(operation, env[PARAMETERS])
        env[INBOX].merge! env[PARAMETERS] = params if params
        req = Rack::Request.new(env)
        return @app.call(env) unless operation.request_body

        validate_request_content_type!(operation, req.content_type)
        parsed_request_body = parse_and_validate_request_body!(operation, req)
        env[REQUEST_BODY] = parsed_request_body
        env[INBOX].merge! parsed_request_body if parsed_request_body.is_a?(Hash)
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

    def validate_query_parameters!(operation, params)
      schema = operation.query_parameters_schema
      return unless schema

      params = filtered_params(schema.raw_schema, params)
      errors = schema.validate(params)
      throw_error(400, serialize_query_parameter_errors(errors)) if errors.any?
      params
    end

    def filtered_params(json_schema, params)
      json_schema['properties']
        .each_with_object({}) do |key_value, result|
          parameter_name = key_value[0]
          parameter_name_symbol = parameter_name.to_sym
          schema = key_value[1]
          next unless params.key?(parameter_name_symbol)

          value = params[parameter_name_symbol]
          result[parameter_name] = parse_parameter(value, schema)
        end
    end

    def serialize_query_parameter_errors(validation_errors)
      validation_errors.map do |error|
        pointer = error['data_pointer'][1..].to_s
        {
          source: { parameter: pointer }
        }.update(ValidationFormat.error_details(error))
      end
    end

    def parse_parameter(value, schema)
      return filtered_params(schema, value) if schema['properties']

      return parse_array_parameter(value, schema) if schema['type'] == 'array'

      parse_simple_value(value, schema)
    end

    def parse_array_parameter(value, schema)
      return value if value.nil? || value.empty?

      array = value.is_a?(Array) ? value : value.split(',')
      return array unless schema['items']

      array.map! { |e| parse_simple_value(e, schema['items']) }
    end

    def parse_simple_value(value, schema)
      return to_boolean(value) if schema['type'] == 'boolean'

      begin
        return Integer(value, 10) if schema['type'] == 'integer'
        return Float(value) if schema['type'] == 'number'
      rescue ArgumentError
        value
      end
      value
    end

    def to_boolean(value)
      return true if value == 'true'
      return false if value == 'false'

      value
    end
  end
end

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

      env[INBOX] = Inbox.new(env)
      catch(:halt) do
        validate_query_parameters!(env, operation, env[PARAMETERS])
        req = Rack::Request.new(env)
        content_type = req.content_type
        return @app.call(env) unless operation.request_body

        validate_request_content_type!(content_type, operation)
        body = req.body.read
        req.body.rewind
        parse_and_validate_request_body!(env, content_type, body, operation)
        @app.call(env)
      end
    end

    private

    def halt(response)
      throw :halt, response
    end

    def parse_and_validate_request_body!(env, content_type, body, operation)
      validate_request_body_presence!(body, operation)
      return if body.empty?

      schema = operation&.request_body_schema(content_type)
      return unless schema

      parsed_request_body = parse_request_body!(body)
      errors = schema.validate(parsed_request_body)
      halt_with_error(400, serialize_request_body_errors(errors)) if errors.any?
      env[INBOX].merge! env[REQUEST_BODY] = Utils.deep_symbolize(parsed_request_body)
    end

    def parse_request_body!(body)
      MultiJson.load(body)
    rescue MultiJson::ParseError => e
      err = { title: 'Failed to parse body as JSON' }
      err[:detail] = e.cause unless ENV['RACK_ENV'] == 'production'
      halt_with_error(400, [err])
    end

    def validate_request_content_type!(content_type, operation)
      return if operation.request_body.dig('content', content_type)

      halt_with_error(415)
    end

    def validate_request_body_presence!(body, operation)
      return unless operation.request_body['required'] && body.empty?

      halt_with_error(415, 'Request body is required')
    end

    def default_error(status, title = Rack::Utils::HTTP_STATUS_CODES[status])
      {
        status: status.to_s,
        title: title
      }
    end

    def halt_with_error(status, errors = [default_error(status)])
      raise RequestInvalidError, errors if @raise

      halt Rack::Response.new(
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

    def validate_query_parameters!(env, operation, params)
      schema = operation.parameters_schema
      return unless schema

      params = filtered_params(schema.raw_schema, params)
      params = Utils.deep_stringify(params)
      errors = schema.validate(params)
      halt_with_error(400, serialize_query_parameter_errors(errors)) if errors.any?
      params = Utils.deep_symbolize(params)
      env[PARAMETERS] = params
      env[INBOX].merge! params
    end

    def filtered_params(json_schema, params)
      json_schema['properties']
        .each_with_object({}) do |key_value, result|
          parameter_name = key_value[0].to_sym
          schema = key_value[1]
          next unless params.key?(parameter_name)

          value = params[parameter_name]
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

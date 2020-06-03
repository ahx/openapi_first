# frozen_string_literal: true

require 'rack'
require 'json_schemer'
require 'multi_json'
require_relative 'inbox'
require_relative 'router_required'
require_relative 'validation_format'

module OpenapiFirst
  class RequestValidation # rubocop:disable Metrics/ClassLength
    prepend RouterRequired

    def initialize(app, _options = {})
      @app = app
    end

    def call(env) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      operation = env[OpenapiFirst::OPERATION]
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

      schema = request_body_schema(content_type, operation)
      return unless schema

      parsed_request_body = parse_request_body!(body)
      errors = validate_json_schema(schema, parsed_request_body)
      halt(error_response(400, serialize_request_body_errors(errors))) if errors.any?
      env[INBOX].merge! env[REQUEST_BODY] = parsed_request_body
    end

    def parse_request_body!(body)
      MultiJson.load(body)
    rescue MultiJson::ParseError => e
      err = { title: 'Failed to parse body as JSON' }
      err[:detail] = e.cause unless ENV['RACK_ENV'] == 'production'
      halt(error_response(400, [err]))
    end

    def validate_request_content_type!(content_type, operation)
      return if operation.request_body.content[content_type]

      halt(error_response(415))
    end

    def validate_request_body_presence!(body, operation)
      return unless operation.request_body.required && body.empty?

      halt(error_response(415, 'Request body is required'))
    end

    def validate_json_schema(schema, object)
      JSONSchemer.schema(schema).validate(object)
    end

    def default_error(status, title = Rack::Utils::HTTP_STATUS_CODES[status])
      {
        status: status.to_s,
        title: title
      }
    end

    def error_response(status, errors = [default_error(status)])
      Rack::Response.new(
        MultiJson.dump(errors: errors),
        status,
        Rack::CONTENT_TYPE => 'application/vnd.api+json'
      ).finish
    end

    def request_body_schema(content_type, operation)
      return unless operation

      operation.request_body.content[content_type]&.fetch('schema')
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
      json_schema = operation.parameters_json_schema
      return unless json_schema

      params = filtered_params(json_schema, params)
      errors = JSONSchemer.schema(json_schema).validate(params)
      halt error_response(400, serialize_query_parameter_errors(errors)) if errors.any?
      env[PARAMETERS] = params
      env[INBOX].merge! params
    end

    def filtered_params(json_schema, params)
      json_schema['properties']
        .each_with_object({}) do |key_value, result|
          parameter_name, schema = key_value
          next unless params.key?(parameter_name)

          value = params[parameter_name]
          result[parameter_name] = parse_parameter(value, schema)
        end
    end

    def serialize_query_parameter_errors(validation_errors)
      validation_errors.map do |error|
        {
          source: { parameter: File.basename(error['data_pointer']) }
        }.update(ValidationFormat.error_details(error))
      end
    end

    def parse_parameter(value, schema)
      return filtered_params(schema, value) if schema['properties']

      begin
        return Integer(value, 10) if schema['type'] == 'integer'
        return Float(value) if schema['type'] == 'number'
      rescue ArgumentError
        value
      end
      return to_boolean(value) if schema['type'] == 'boolean'

      value
    end

    def to_boolean(value)
      return true if value == 'true'
      return false if value == 'false'

      value
    end
  end
end

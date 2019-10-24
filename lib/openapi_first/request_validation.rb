# frozen_string_literal: true

require 'rack'
require 'json_schemer'
require 'multi_json'
require_relative 'query_parameters'
require_relative 'validation_format'

module OpenapiFirst
  class RequestValidation
    def initialize(app, allow_additional_parameters: false)
      @app = app
      @allow_additional_parameters = allow_additional_parameters
    end

    def call(env) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      operation = env[OpenapiFirst::OPERATION]
      return @app.call(env) unless operation

      req = Rack::Request.new(env)
      catch(:halt) do
        validate_query_parameters!(env, operation, req.params)
        content_type = req.content_type
        return @app.call(env) unless operation.request_body

        validate_request_content_type!(content_type, operation)
        body = req.body.read
        req.body.rewind
        parse_and_validate_request_body!(env, content_type, body, operation)
        @app.call(env)
      end
    end

    def halt(response)
      throw :halt, response
    end

    def parse_and_validate_request_body!(env, content_type, body, operation)
      validate_request_body_presence!(body, operation)
      return if body.empty?

      schema = request_body_schema(content_type, operation)
      return unless schema

      parsed_request_body = MultiJson.load(body)
      errors = validate_json_schema(schema, parsed_request_body)
      if errors.any?
        halt(error_response(400, serialize_request_body_errors(errors)))
      end
      env[OpenapiFirst::REQUEST_BODY] = parsed_request_body
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

    def request_body_schema(content_type, endpoint)
      return unless endpoint

      endpoint.request_body.content[content_type]&.fetch('schema')
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
      json_schema = QueryParameters.new(
        operation: operation,
        allow_additional_parameters: @allow_additional_parameters
      ).to_json_schema

      return unless json_schema

      errors = JSONSchemer.schema(json_schema).validate(params)
      if errors.any?
        halt error_response(400, serialize_query_parameter_errors(errors))
      end
      env[QUERY_PARAMS] = allowed_params(json_schema, params)
    end

    def allowed_params(json_schema, params)
      json_schema['properties']
        .keys
        .each_with_object({}) do |parameter_name, filtered|
          next unless params.key?(parameter_name)

          filtered[parameter_name] = params[parameter_name]
        end
    end

    def serialize_query_parameter_errors(validation_errors)
      validation_errors.map do |error|
        {
          source: {
            parameter: File.basename(error['data_pointer'])
          }
        }.update(ValidationFormat.error_details(error))
      end
    end
  end
end

# frozen_string_literal: true

require 'rack'
require 'json_schemer'
require 'multi_json'
require_relative 'error_response_method'
require_relative 'validation_format'

module OpenapiFirst
  class RequestBodyValidation
    include ErrorResponseMethod

    def initialize(app)
      @app = app
    end

    def call(env) # rubocop:disable Metrics/MethodLength
      operation = env[OpenapiFirst::OPERATION]
      return @app.call(env) unless operation&.request_body

      req = Rack::Request.new(env)
      content_type = req.content_type
      body = req.body
      catch(:halt) do
        validate_request_content_type!(content_type, operation)
        validate_request_body_presence!(env, body, operation)
        parse_and_validate_request_body!(env, content_type, body, operation)
        @app.call(env)
      end
    end

    def halt(response)
      throw :halt, response
    end

    def validate_request_content_type!(content_type, operation)
      return if content_type_valid?(content_type, operation)

      halt(error_response(415))
    end

    def validate_request_body_presence!(env, body, operation)
      return unless body.size.zero?

      if operation.request_body.required
        halt(error_response(415, 'Request body is required'))
      end
      halt(@app.call(env))
    end

    def parse_and_validate_request_body!(env, content_type, body, operation)
      schema = request_body_schema(content_type, operation)
      return unless schema

      parsed_request_body = MultiJson.load(body)
      errors = validate_json_schema(schema, parsed_request_body)
      halt(error_response(400, serialize_errors(errors))) if errors&.any?
      env[OpenapiFirst::REQUEST_BODY] = parsed_request_body
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

    def content_type_valid?(content_type, endpoint)
      endpoint.request_body.content[content_type]
    end

    def request_body_schema(content_type, endpoint)
      return unless endpoint

      endpoint.request_body.content[content_type]&.fetch('schema')
    end

    def serialize_errors(validation_errors)
      validation_errors.map do |error|
        {
          source: {
            pointer: error['data_pointer']
          }
        }.update(ValidationFormat.error_details(error))
      end
    end
  end
end

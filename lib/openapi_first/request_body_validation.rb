# frozen_string_literal: true

require 'rack'
require 'json_schemer'
require 'multi_json'

module OpenapiFirst
  class RequestBodyValidation
    JSON_API_CONTENT_TYPE = 'application/vnd.api+json'

    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      endpoint = env[OpenapiFirst::OPERATION]
      return @app.call(env) unless endpoint&.request_body

      content_type = req.content_type
      return error_response(415) unless content_type_valid?(content_type, endpoint)

      if req.body.size.zero?
        return error_response(415, 'Request body is required') if endpoint.request_body.required
        return @app.call(env)
      end

      schema = request_body_schema(content_type, endpoint)
      if schema
        parsed_request_body = MultiJson.load(req.body)
        errors = validate_json_schema(schema, parsed_request_body)
        return error_response(400, serialize_errors(errors)) if errors&.any?

        env[OpenapiFirst::REQUEST_BODY] = parsed_request_body
      end

      @app.call(env)
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
        Rack::CONTENT_TYPE => JSON_API_CONTENT_TYPE
      )
    end

    def content_type_valid?(content_type, endpoint)
      endpoint.request_body.content[content_type]
    end

    def request_body_schema(content_type, endpoint)
      return unless endpoint

      endpoint.request_body.content[content_type]&.fetch('schema')
    end


    def request_body_schema(content_type, endpoint)
      return unless endpoint

      endpoint.request_body.content[content_type]&.fetch('schema')
    end

    def serialize_errors(validation_errors)
      validation_errors.each_with_object([]) do |error, errors|
        error_object = {
          source: {
            pointer: error['data_pointer']
          }
        }
        if error['type'] == 'pattern'
          error_object.update(
            title: 'is not valid',
            detail: "does not match pattern '#{error['schema']['pattern']}'",
          )
        elsif error['type'] == 'required'
          error['details']['missing_keys'].each do |parameter|
            error_object.update(
              title: 'is missing required property "name"'
            )
          end
        else
          error_object.update(
            title: 'is not valid'
          )
        end
        errors << error_object
      end
    end
  end
end
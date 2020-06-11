# frozen_string_literal: true

require 'json_schemer'
require 'multi_json'
require_relative 'router_required'
require_relative 'validation'

module OpenapiFirst
  class ResponseValidation
    prepend RouterRequired

    def initialize(app)
      @app = app
    end

    def call(env)
      operation = env[OPERATION]
      return @app.call(env) unless operation

      status, headers, body = @app.call(env)
      content_type = headers[Rack::CONTENT_TYPE]
      response_schema = operation.response_schema_for(status, content_type)
      validate_response_body(response_schema, body) if response_schema

      [status, headers, body]
    end

    private

    def validate_response_body(schema, response)
      full_body = +''
      response.each { |chunk| full_body << chunk }
      data = full_body.empty? ? {} : load_json(full_body)
      errors = JSONSchemer.schema(schema).validate(data).to_a.map do |error|
        error_message_for(error)
      end
      raise ResponseBodyInvalidError, errors.join(', ') if errors.any?
    end

    def load_json(string)
      MultiJson.load(string)
    rescue MultiJson::ParseError
      string
    end

    def error_message_for(error)
      err = ValidationFormat.error_details(error)
      [err[:title], error['data_pointer'], err[:detail]].compact.join(' ')
    end
  end
end

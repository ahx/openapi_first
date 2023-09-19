# frozen_string_literal: true

require 'multi_json'
require_relative 'use_router'
require_relative 'error_format'

module OpenapiFirst
  class ResponseValidation
    prepend UseRouter

    def initialize(app, _options = {})
      @app = app
    end

    def call(env)
      operation = env[OPERATION]
      return @app.call(env) unless operation

      response = @app.call(env)
      validate(response, operation)
      response
    end

    def validate(response, operation)
      status, headers, body = response.to_a
      return validate_status_only(operation, status) if status == 204

      content_type = headers[Rack::CONTENT_TYPE]
      response_schema = operation.response_body_schema(status, content_type)
      validate_response_body(response_schema, body) if response_schema
      validate_response_headers(operation, status, headers)
    end

    private

    def validate_status_only(operation, status)
      operation.response_for(status)
    end

    def validate_response_body(schema, response)
      full_body = +''
      response.each { |chunk| full_body << chunk }
      data = full_body.empty? ? {} : load_json(full_body)
      errors = schema.validate(data)
      errors = errors.to_a.map! do |error|
        format_response_error(error)
      end
      raise ResponseBodyInvalidError, errors.join(', ') if errors.any?
    end

    def validate_response_headers(operation, status, response_headers)
      response_header_definitions = operation.response_for(status)&.dig('headers')
      return unless response_header_definitions

      unpacked_headers = unpack_response_headers(response_header_definitions, response_headers)
      response_header_definitions.each do |name, definition|
        next if name == 'Content-Type'

        validate_response_header(name, definition, unpacked_headers, openapi_version: operation.openapi_version)
      end
    end

    def validate_response_header(name, definition, unpacked_headers, openapi_version:)
      unless unpacked_headers.key?(name)
        raise ResponseHeaderInvalidError, "Required response header '#{name}' is missing" if definition['required']

        return
      end

      return unless definition.key?('schema')

      validation = SchemaValidation.new(definition['schema'], openapi_version:)
      value = unpacked_headers[name]
      errors = validation.validate(value).to_a.map! { |error| format_header_error(error, name) }
      raise ResponseHeaderInvalidError, errors.join(', ') if errors.any?
    end

    def unpack_response_headers(response_header_definitions, response_headers)
      headers_as_parameters = response_header_definitions.map do |name, definition|
        definition.merge('name' => name)
      end
      OpenapiParameters::Header.new(headers_as_parameters).unpack(response_headers)
    end

    def format_response_error(error)
      return "Write-only field appears in response: #{error['data_pointer']}" if error['type'] == 'writeOnly'

      JSONSchemer::Errors.pretty(error)
    end

    def format_header_error(error, name)
      "Response header '#{name}' #{ErrorFormat.error_details(error)[:title]}"
    end

    def load_json(string)
      MultiJson.load(string)
    rescue MultiJson::ParseError
      string
    end
  end
end

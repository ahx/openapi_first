# frozen_string_literal: true

module OpenapiFirst
  class ResponseValidation
    class Validator
      def initialize(operation)
        @operation = operation
      end

      def validate(response)
        status, headers, body = response.to_a

        content_type = headers[Rack::CONTENT_TYPE]
        response_definition = response_for(operation, status, content_type)
        validate_response_body(response_definition.content_schema, body)
        validate_response_headers(response_definition.headers, headers)
      end

      private

      attr_reader :operation

      def response_for(operation, status, content_type)
        response = operation.response_for(status, content_type)
        return response if response

        unless operation.response_status_defined?(status)
          message = "Response status '#{status}' not found at '#{operation.name}'"
          raise OpenapiFirst::ResponseCodeNotFoundError, message
        end
        if content_type.nil? || content_type.empty?
          message = "Response Content-Type for '#{operation.name}' must not be empty"
          raise OpenapiFirst::ResponseContentTypeNotFoundError, message
        end

        message = "Content-Type #{content_type} not found at '#{operation.name}'"
        raise OpenapiFirst::ResponseContentTypeNotFoundError, message
      end

      def validate_response_body(schema, response)
        return unless schema

        full_body = +''
        response.each { |chunk| full_body << chunk }
        data = full_body.empty? ? {} : load_json(full_body)
        validation = schema.validate(data)
        raise ResponseBodyInvalidError, validation.message if validation.error?
      end

      def validate_response_headers(response_header_definitions, response_headers)
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

        validation = Schema.new(definition['schema'], openapi_version:)
        value = unpacked_headers[name]
        schema_validation = validation.validate(value)
        raise ResponseHeaderInvalidError, schema_validation.message if schema_validation.error?
      end

      def unpack_response_headers(response_header_definitions, response_headers)
        headers_as_parameters = response_header_definitions.map do |name, definition|
          definition.merge('name' => name, 'in' => 'header')
        end
        OpenapiParameters::Header.new(headers_as_parameters).unpack(response_headers)
      end

      def format_response_error(error)
        return "Write-only field appears in response: #{error['data_pointer']}" if error['type'] == 'writeOnly'

        JSONSchemer::Errors.pretty(error)
      end

      def load_json(string)
        MultiJson.load(string)
      rescue MultiJson::ParseError
        string
      end
    end
  end
end

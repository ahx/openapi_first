# frozen_string_literal: true

require_relative '../failure'

module OpenapiFirst
  module ResponseValidation
    class Validator
      def initialize(operation)
        @operation = operation
      end

      def validate(rack_response)
        return unless operation

        response = Rack::Response[*rack_response.to_a]
        catch Failure::FAILURE do
          response_definition = response_for(operation, response.status, response.content_type)
          validate_response_body(response_definition.content_schema, response.body)
          validate_response_headers(response_definition.headers, response.headers)
          nil
        end
      end

      private

      attr_reader :operation

      def response_for(operation, status, content_type)
        response = operation.response_for(status, content_type)
        return response if response

        unless operation.response_status_defined?(status)
          message = "Response status '#{status}' not found for '#{operation.name}'"
          Failure.fail!(:response_not_found, message:)
        end
        if content_type.nil? || content_type.empty?
          message = "Content-Type for '#{operation.name}' must not be empty"
          Failure.fail!(:invalid_response_header, message:)
        end

        message = "Content-Type '#{content_type}' is not defined for '#{operation.name}'"
        Failure.fail!(:invalid_response_header, message:)
      end

      def validate_response_body(schema, response)
        return unless schema

        full_body = +''
        response.each { |chunk| full_body << chunk }
        data = full_body.empty? ? {} : load_json(full_body)
        validation = schema.validate(data)
        Failure.fail!(:invalid_response_body, errors: validation.errors) if validation.error?
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
          if definition['required']
            Failure.fail!(:invalid_response_header,
                          message: "Required response header '#{name}' is missing")
          end

          return
        end

        return unless definition.key?('schema')

        validation = Schema.new(definition['schema'], openapi_version:)
        value = unpacked_headers[name]
        validation_result = validation.validate(value)
        return unless validation_result.error?

        Failure.fail!(:invalid_response_header,
                      errors: validation_result.errors)
      end

      def unpack_response_headers(response_header_definitions, response_headers)
        headers_as_parameters = response_header_definitions.map do |name, definition|
          definition.merge('name' => name, 'in' => 'header')
        end
        OpenapiParameters::Header.new(headers_as_parameters).unpack(response_headers)
      end

      def load_json(string)
        MultiJson.load(string)
      rescue MultiJson::ParseError
        string
      end
    end
  end
end

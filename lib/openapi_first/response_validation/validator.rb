# frozen_string_literal: true

require_relative '../failure'

module OpenapiFirst
  module ResponseValidation
    # Validates a RuntimeResponse against an Operation.
    class Validator
      def initialize(operation, openapi_version:)
        @operation = operation
        @openapi_version = openapi_version
      end

      def call(runtime_response)
        return unless operation

        catch Failure::FAILURE do
          validate_defined(runtime_response)
          response_definition = runtime_response.response_definition
          validate_response_body(response_definition.content_schema, runtime_response)
          validate_response_headers(response_definition.headers, runtime_response.headers)
          nil
        end
      end

      private

      attr_reader :operation

      def validate_defined(runtime_response)
        return if runtime_response.known?

        unless runtime_response.known_status?
          message = "Response status '#{runtime_response.status}' not found for '#{runtime_response.name}'"
          Failure.fail!(:response_not_found, message:)
        end

        content_type = runtime_response.content_type
        if content_type.nil? || content_type.empty?
          message = "Content-Type for '#{runtime_response.name}' must not be empty"
          Failure.fail!(:invalid_response_header, message:)
        end

        message = "Content-Type '#{content_type}' is not defined for '#{runtime_response.name}'"
        Failure.fail!(:invalid_response_header, message:)
      end

      def validate_response_body(schema, runtime_response)
        return unless schema

        begin
          parsed_body = runtime_response.body
        rescue ParseError => e
          Failure.fail!(:invalid_response_body, message: e.message)
        end

        validation = build_schema(schema).validate(parsed_body)
        Failure.fail!(:invalid_response_body, errors: validation.errors) if validation.error?
      end

      def validate_response_headers(response_header_definitions, unpacked_headers)
        return unless response_header_definitions

        response_header_definitions.each do |name, definition|
          next if name == 'Content-Type'

          validate_response_header(name, definition, unpacked_headers)
        end
      end

      def validate_response_header(name, definition, unpacked_headers)
        unless unpacked_headers.key?(name)
          if definition['required']
            Failure.fail!(:invalid_response_header,
                          message: "Required response header '#{name}' is missing")
          end

          return
        end

        return unless definition.key?('schema')

        validation = build_schema(definition['schema'])
        value = unpacked_headers[name]
        validation_result = validation.validate(value)
        return unless validation_result.error?

        Failure.fail!(:invalid_response_header,
                      errors: validation_result.errors)
      end

      def load_json(string)
        MultiJson.load(string)
      rescue MultiJson::ParseError
        string
      end

      def build_schema(schema)
        Schema.new(schema, openapi_version: @openapi_version, write: false)
      end
    end
  end
end

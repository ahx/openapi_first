# frozen_string_literal: true

require_relative '../failure'
require_relative 'request_body_validator'

module OpenapiFirst
  module RequestValidation
    # Validates a RuntimeRequest against an Operation.
    class Validator
      def initialize(operation, schema_builder:)
        @operation = operation
        @schema_builder = schema_builder
      end

      def validate(runtime_request)
        catch Failure::FAILURE do
          validate_defined(runtime_request)
          validate_parameters!(runtime_request)
          validate_request_body!(runtime_request)
          nil
        end
      end

      private

      attr_reader :operation, :raw_path_params

      def validate_defined(request)
        return if request.known?
        return Failure.fail!(:not_found) unless request.known_path?

        Failure.fail!(:method_not_allowed) unless request.known_request_method?
      end

      def validate_parameters!(request)
        validate_query_params!(request)
        validate_path_params!(request)
        validate_cookie_params!(request)
        validate_header_params!(request)
      end

      def validate_path_params!(request)
        @path_parameters_schema ||= build_schema(operation.path_parameters_schema)
        return unless @path_parameters_schema

        validation = @path_parameters_schema.validate(request.path_parameters)
        Failure.fail!(:invalid_path, errors: validation.errors) if validation.error?
      end

      def validate_query_params!(request)
        @query_parameters_schema ||= build_schema(operation.query_parameters_schema)
        return unless @query_parameters_schema

        validation = @query_parameters_schema.validate(request.query)
        Failure.fail!(:invalid_query, errors: validation.errors) if validation.error?
      end

      def validate_cookie_params!(request)
        @cookie_parameters_schema ||= build_schema(operation.cookie_parameters_schema)
        return unless @cookie_parameters_schema

        validation = @cookie_parameters_schema.validate(request.cookies)
        Failure.fail!(:invalid_cookie, errors: validation.errors) if validation.error?
      end

      def validate_header_params!(request)
        @header_parameters_schema ||= build_schema(operation.header_parameters_schema)
        return unless @header_parameters_schema

        validation = @header_parameters_schema.validate(request.headers)
        Failure.fail!(:invalid_header, errors: validation.errors) if validation.error?
      end

      def validate_request_body!(request)
        return unless operation.request_body

        RequestBodyValidator.new(operation.request_body, schema_builder: @schema_builder)
                            .validate!(request.body, request.content_type)
      rescue ParseError => e
        Failure.fail!(:invalid_body, message: e.message)
      end

      def build_schema(schema)
        return unless schema

        @schema_builder.build_schema(schema)
      end
    end
  end
end

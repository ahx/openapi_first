# frozen_string_literal: true

require_relative '../failure'
require_relative 'request_body_validator'

module OpenapiFirst
  module RequestValidation
    # Validates a RuntimeRequest against an Operation.
    class Validator
      def initialize(path_item, operation, schema_builder:)
        @path_item = path_item
        @operation = operation
        @schema_builder = schema_builder
        @validators = []
        @validators << method(:validate_path_params!) if path_parameters
        @validators << method(:validate_query_params!) if query_parameters
        @validators << method(:validate_header_params!) if header_parameters
        @validators << method(:validate_cookie_params!) if cookie_parameters
        @validators << method(:validate_request_body!) if operation&.request_body
      end

      def call(runtime_request)
        catch Failure::FAILURE do
          validate_defined(runtime_request)
          @validators.each { |v| v.call(runtime_request) }
          nil
        end
      end

      private

      attr_reader :operation, :path_item, :raw_path_params

      def validate_defined(request)
        return if request.known?
        return Failure.fail!(:not_found) unless request.known_path?

        Failure.fail!(:method_not_allowed) unless request.known_request_method?
      end

      def validate_path_params!(request)
        @path_parameters_schema ||= build_parameters_schema(path_parameters)

        validation = @path_parameters_schema.validate(request.path_parameters)
        Failure.fail!(:invalid_path, errors: validation.errors) if validation.error?
      end

      def validate_query_params!(request)
        @query_parameters_schema ||= build_parameters_schema(query_parameters)

        validation = @query_parameters_schema.validate(request.query)
        Failure.fail!(:invalid_query, errors: validation.errors) if validation.error?
      end

      def validate_cookie_params!(request)
        @cookie_parameters_schema ||= build_parameters_schema(cookie_parameters)

        validation = @cookie_parameters_schema.validate(request.cookies)
        Failure.fail!(:invalid_cookie, errors: validation.errors) if validation.error?
      end

      IGNORED_HEADERS = Set['Content-Type', 'Accept', 'Authorization'].freeze
      private_constant :IGNORED_HEADERS

      def header_parameters
        return unless operation&.header_parameters || path_item&.header_parameters

        Array(operation.header_parameters).concat(Array(path_item.header_parameters)).reject do |p|
          IGNORED_HEADERS.include?(p['name'])
        end
      end

      def path_parameters
        return unless operation&.path_parameters || path_item&.path_parameters

        Array(operation.path_parameters).concat(Array(path_item.path_parameters))
      end

      def query_parameters
        return unless operation&.query_parameters || path_item&.query_parameters

        Array(operation.query_parameters).concat(Array(path_item.query_parameters))
      end

      def cookie_parameters
        return unless operation&.cookie_parameters || path_item&.cookie_parameters

        Array(operation.cookie_parameters).concat(Array(path_item.cookie_parameters))
      end

      def validate_header_params!(request)
        @header_parameters_schema ||= build_parameters_schema(header_parameters)

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

      def build_parameters_schema(parameters)
        return unless parameters&.any?

        init_schema = {
          'type' => 'object',
          'properties' => {},
          'required' => []
        }
        schema = parameters.each_with_object(init_schema) do |parameter_def, result|
          parameter = OpenapiParameters::Parameter.new(parameter_def)
          result['properties'][parameter.name] = parameter.schema if parameter.schema
          result['required'] << parameter.name if parameter.required?
        end
        @schema_builder.build_schema(schema)
      end
    end
  end
end

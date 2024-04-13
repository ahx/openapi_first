# frozen_string_literal: true

require_relative '../failure'
require_relative 'request_body_validator'

module OpenapiFirst
  module RequestValidation
    # Validates a Request against an Operation.
    class Validator
      def initialize(path_item, operation, config:, openapi_version:)
        @path_item = path_item
        @operation = operation
        @config = config
        @openapi_version = openapi_version
        @validators = []
        @parameter_schemas = build_parameter_schemas
        @validators << method(:validate_path_params!) if parameter_schemas[:path]
        @validators << method(:validate_query_params!) if parameter_schemas[:query]
        @validators << method(:validate_header_params!) if parameter_schemas[:header]
        @validators << method(:validate_cookie_params!) if parameter_schemas[:cookie]
        @validators << method(:validate_request_body!) if operation&.request_body
      end

      def call(request)
        catch Failure::FAILURE do
          validate_defined(request)
          @validators.each { |v| v.call(request) }
          nil
        end
      end

      private

      attr_reader :operation, :path_item, :config, :openapi_version, :parameter_schemas

      def build_parameter_schemas
        schemas = {}
        add_parameters_to_schemas(operation['parameters'], schemas) if operation
        add_parameters_to_schemas(path_item['parameters'], schemas) if path_item
        after_property_validation = config.hooks[:after_request_parameter_property_validation]
        schemas.transform_values! { Schema.new(_1, openapi_version:, after_property_validation:) }
      end

      def add_parameters_to_schemas(parameters, schemas)
        return schemas if parameters.nil?

        parameters.each_with_object(schemas) do |parameter_def, _result|
          parameter = OpenapiParameters::Parameter.new(parameter_def)
          next if parameter.location == 'header' && IGNORED_HEADERS.include?(parameter.name)

          params = schemas[parameter.location&.to_sym] ||= {
            'type' => 'object',
            'properties' => {},
            'required' => []
          }
          params['properties'][parameter.name] = parameter.schema if parameter.schema
          params['required'] << parameter.name if parameter.required?
        end
      end

      def validate_defined(request)
        return if request.known?
        return Failure.fail!(:not_found) unless request.path_item

        Failure.fail!(:method_not_allowed) unless request.operation
      end

      def validate_path_params!(request)
        validation = parameter_schemas[:path].validate(request.path_parameters)
        Failure.fail!(:invalid_path, errors: validation.errors) if validation.error?
      end

      def validate_query_params!(request)
        validation = parameter_schemas[:query].validate(request.query)
        Failure.fail!(:invalid_query, errors: validation.errors) if validation.error?
      end

      def validate_cookie_params!(request)
        validation = parameter_schemas[:cookie].validate(request.cookies)
        Failure.fail!(:invalid_cookie, errors: validation.errors) if validation.error?
      end

      IGNORED_HEADERS = Set['Content-Type', 'Accept', 'Authorization'].freeze
      private_constant :IGNORED_HEADERS

      def validate_header_params!(request)
        validation = parameter_schemas[:header].validate(request.headers)
        Failure.fail!(:invalid_header, errors: validation.errors) if validation.error?
      end

      def validate_request_body!(request)
        return unless operation.request_body

        RequestBodyValidator.new(operation.request_body, openapi_version:, config:)
                            .validate!(request.body, request.content_type)
      rescue ParseError => e
        Failure.fail!(:invalid_body, message: e.message)
      end
    end
  end
end

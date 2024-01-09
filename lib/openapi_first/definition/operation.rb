# frozen_string_literal: true

require 'forwardable'
require 'set'
require 'openapi_parameters'
require_relative 'request_body'
require_relative 'responses'

module OpenapiFirst
  class Definition
    class Operation
      extend Forwardable
      def_delegators :operation_object,
                     :[],
                     :dig

      WRITE_METHODS = Set.new(%w[post put patch delete]).freeze
      private_constant :WRITE_METHODS

      def initialize(path, request_method, path_item_object, openapi_version:)
        @path = path
        @method = request_method
        @path_item_object = path_item_object
        @openapi_version = openapi_version
        @operation_object = @path_item_object[request_method]
      end

      attr_reader :path, :method, :openapi_version
      alias request_method method

      def operation_id
        operation_object['operationId']
      end

      def read?
        !write?
      end

      def write?
        WRITE_METHODS.include?(method)
      end

      def request_body
        @request_body ||= RequestBody.new(operation_object['requestBody'], self) if operation_object['requestBody']
      end

      def response_status_defined?(status)
        responses.status_defined?(status)
      end

      def_delegators :responses, :response_for

      def schema_for(content_type)
        content = @request_body_object['content']
        return unless content&.any?

        content_schemas&.fetch(content_type) do
          type = content_type.split(';')[0]
          content_schemas[type] || content_schemas["#{type.split('/')[0]}/*"] || content_schemas['*/*']
        end
      end

      def name
        @name ||= "#{method.upcase} #{path} (#{operation_id})"
      end

      def path_parameters
        all_parameters['path']
      end

      def query_parameters
        all_parameters['query']
      end

      def header_parameters
        all_parameters['header']
      end

      def cookie_parameters
        all_parameters['cookie']
      end

      def path_parameters_schema
        @path_parameters_schema ||= build_schema(path_parameters)
      end

      def query_parameters_schema
        @query_parameters_schema ||= build_schema(query_parameters)
      end

      def header_parameters_schema
        @header_parameters_schema ||= build_schema(header_parameters)
      end

      def cookie_parameters_schema
        @cookie_parameters_schema ||= build_schema(cookie_parameters)
      end

      private

      IGNORED_HEADERS = Set['Content-Type', 'Accept', 'Authorization'].freeze
      private_constant :IGNORED_HEADERS

      def all_parameters
        @all_parameters ||= (@path_item_object.fetch('parameters', []) + operation_object.fetch('parameters', []))
                            .reject { |p| p['in'] == 'header' && IGNORED_HEADERS.include?(p['name']) }
                            .group_by { _1['in'] }
      end

      def build_schema(parameters)
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
        Schema.new(schema, openapi_version: @openapi_version)
      end

      def responses
        @responses ||= Responses.new(self, operation_object['responses'])
      end

      attr_reader :operation_object

      def build_parameters(parameters, klass)
        klass.new(parameters, openapi_version:) if parameters.any?
      end
    end
  end
end

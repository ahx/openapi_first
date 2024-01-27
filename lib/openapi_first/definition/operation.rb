# frozen_string_literal: true

require 'forwardable'
require 'set'
require 'openapi_parameters'
require_relative 'request_body'
require_relative 'responses'

module OpenapiFirst
  class Definition
    # Represents an operation object in the OpenAPI 3.X specification.
    # Use this class to access information about the operation. Use `#[key]` to read the raw data.
    # When using the middleware you can access the operation object via `env[OpenapiFirst::REQUEST].operation`.
    class Operation
      extend Forwardable

      def_delegators :operation_object,
                     :[]

      WRITE_METHODS = Set.new(%w[post put patch delete]).freeze
      private_constant :WRITE_METHODS

      def initialize(path, request_method, path_item_object, openapi_version:)
        @path = path
        @method = request_method
        @path_item_object = path_item_object
        @openapi_version = openapi_version
        @operation_object = @path_item_object[request_method]
      end

      # Returns the path of the operation as in the API description.
      # @return [String] The path of the operation.
      attr_reader :path

      # Returns the (downcased) request method of the operation.
      # Example: "get"
      # @return [String] The request method of the operation.
      attr_reader :method
      alias request_method method

      attr_reader :openapi_version # :nodoc:

      # Returns the operation ID as defined in the API description.
      # @return [String, nil]
      def operation_id
        operation_object['operationId']
      end

      # Checks if the operation is a read operation.
      # This is the case for all request methods except POST, PUT, PATCH and DELETE.
      # @return [Boolean] `true` if the operation is a read operation, `false` otherwise.
      def read?
        !write?
      end

      # Checks if the operation is a write operation.
      # This is the case for POST, PUT, PATCH and DELETE request methods.
      # @return [Boolean] `true` if the operation is a write operation, `false` otherwise.
      def write?
        WRITE_METHODS.include?(method)
      end

      # Returns the request body definition if defined in the API description.
      # @return [RequestBody, nil] The request body of the operation, or `nil` if not present.
      def request_body
        @request_body ||= RequestBody.new(operation_object['requestBody'], self) if operation_object['requestBody']
      end

      # Checks if a response status is defined for this operation.
      # @param status [Integer, String] The response status to check.
      # @return [Boolean] `true` if the response status is defined, `false` otherwise.
      def response_status_defined?(status)
        responses.status_defined?(status)
      end

      # Returns the response object for a given status.
      # @param status [Integer, String] The response status.
      # @param content_type [String] Content-Type of the current response.
      # @return [Response, nil] The response object for the given status, or `nil` if not found.
      def response_for(status, content_type)
        responses.response_for(status, content_type)
      end

      # Returns the schema for a given content type.
      # @param content_type [String] The content type.
      # @return [Schema, nil] The schema for the given content type, or `nil` if not found.
      def schema_for(content_type)
        content = @request_body_object['content']
        return unless content&.any?

        content_schemas&.fetch(content_type) do
          type = content_type.split(';')[0]
          content_schemas[type] || content_schemas["#{type.split('/')[0]}/*"] || content_schemas['*/*']
        end
      end

      # Returns a unique name for this operation. Used for generating error messages.
      # @visibility private
      def name
        @name ||= "#{method.upcase} #{path} (#{operation_id})"
      end

      # Returns the path parameters of the operation.
      # @return [Array<Hash>] The path parameters of the operation.
      def path_parameters
        all_parameters['path']
      end

      # Returns the query parameters of the operation.
      # Returns parameters defined on the path and in the operation.
      # @return [Array<Hash>] The query parameters of the operation.
      def query_parameters
        all_parameters['query']
      end

      # Returns the header parameters of the operation.
      # Returns parameters defined on the path and in the operation.
      # @return [Array<Hash>] The header parameters of the operation.
      def header_parameters
        all_parameters['header']
      end

      # Returns the cookie parameters of the operation.
      # Returns parameters defined on the path and in the operation.
      # @return [Array<Hash>] The cookie parameters of the operation.
      def cookie_parameters
        all_parameters['cookie']
      end

      # Returns the schema for the path parameters.
      # @visibility private
      # @return [Schema, nil] The schema for the path parameters, or `nil` if not found.
      def path_parameters_schema
        @path_parameters_schema ||= build_schema(path_parameters)
      end

      # Returns the schema for the query parameters.
      # @visibility private
      # @return [Schema, nil] The schema for the query parameters, or `nil` if not found.
      def query_parameters_schema
        @query_parameters_schema ||= build_schema(query_parameters)
      end

      # Returns the schema for the header parameters.
      # @visibility private
      # @return [Schema, nil] The schema for the header parameters, or `nil` if not found.
      def header_parameters_schema
        @header_parameters_schema ||= build_schema(header_parameters)
      end

      # Returns the schema for the cookie parameters.
      # @visibility private
      # @return [Schema, nil] The schema for the cookie parameters, or `nil` if not found.
      def cookie_parameters_schema
        @cookie_parameters_schema ||= build_schema(cookie_parameters)
      end

      private

      WRITE_METHODS = Set.new(%w[post put patch delete]).freeze

      IGNORED_HEADERS = Set['Content-Type', 'Accept', 'Authorization'].freeze

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

# frozen_string_literal: true

require 'forwardable'
require 'set'
require_relative 'schema_validation'
require_relative 'utils'
require_relative 'operation_schemas'

module OpenapiFirst
  class Operation
    extend Forwardable
    def_delegators :operation_object,
                   :[],
                   :dig

    WRITE_METHODS = Set.new(%w[post put patch delete]).freeze
    private_constant :WRITE_METHODS

    attr_reader :path, :method

    def initialize(path, request_method, path_item_object)
      @path = path
      @method = request_method
      @path_item_object = path_item_object
    end

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
      operation_object['requestBody']
    end

    def response_schema_for(status, content_type)
      content = response_for(status)['content']
      return if content.nil? || content.empty?

      raise ResponseInvalid, "Response has no content-type for '#{name}'" unless content_type

      media_type = find_content_for_content_type(content, content_type)

      unless media_type
        message = "Response content type not found '#{content_type}' for '#{name}'"
        raise ResponseContentTypeNotFoundError, message
      end
      schema = media_type['schema']
      SchemaValidation.new(schema, write: false) if schema
    end

    def request_body_schema(request_content_type)
      content = operation_object.dig('requestBody', 'content')
      media_type = find_content_for_content_type(content, request_content_type)
      schema = media_type&.fetch('schema', nil)
      return unless schema

      SchemaValidation.new(schema, write: write?)
    end

    def response_for(status)
      response_content = response_by_code(status)
      return response_content if response_content

      message = "Response status code or default not found: #{status} for '#{name}'"
      raise OpenapiFirst::ResponseCodeNotFoundError, message
    end

    def name
      @name ||= "#{method.upcase} #{path} (#{operation_id})"
    end

    def valid_request_content_type?(request_content_type)
      content = operation_object.dig('requestBody', 'content')
      return unless content

      !!find_content_for_content_type(content, request_content_type)
    end

    def query_parameters
      @query_parameters ||= all_parameters.filter { |p| p['in'] == 'query' }
    end

    def path_parameters
      @path_parameters ||= all_parameters.filter { |p| p['in'] == 'path' }
    end

    def all_parameters
      @all_parameters ||= begin
        parameters = @path_item_object['parameters']&.dup || []
        parameters_on_operation = operation_object['parameters']
        parameters.concat(parameters_on_operation) if parameters_on_operation
        parameters
      end
    end

    # visibility: private
    def schemas
      @schemas ||= OperationSchemas.new(self)
    end

    private

    def response_by_code(status)
      operation_object.dig('responses', status.to_s) ||
        operation_object.dig('responses', "#{status / 100}XX") ||
        operation_object.dig('responses', "#{status / 100}xx") ||
        operation_object.dig('responses', 'default')
    end

    def operation_object
      @path_item_object[method]
    end

    def find_content_for_content_type(content, request_content_type)
      content.fetch(request_content_type) do |_|
        type = request_content_type.split(';')[0]
        content[type] || content["#{type.split('/')[0]}/*"] || content['*/*']
      end
    end
  end
end

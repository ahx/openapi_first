# frozen_string_literal: true

require 'forwardable'
require 'set'
require_relative 'schema_validation'
require_relative 'utils'
require_relative 'response_object'

module OpenapiFirst
  class Operation # rubocop:disable Metrics/ClassLength
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

    def parameters_schema
      @parameters_schema ||= begin
        parameters_json_schema = build_parameters_json_schema
        parameters_json_schema && SchemaValidation.new(parameters_json_schema)
      end
    end

    def query_parameters_schema
      @query_parameters_schema ||= begin
        query_parameters_json_schema = build_query_parameters_json_schema
        query_parameters_json_schema && SchemaValidation.new(query_parameters_json_schema)
      end
    end

    def content_types_for(status)
      response_for(status)['content']&.keys
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
      "#{method.upcase} #{path} (#{operation_id})"
    end

    def valid_request_content_type?(request_content_type)
      content = operation_object.dig('requestBody', 'content')
      return unless content

      !!find_content_for_content_type(content, request_content_type)
    end

    def query_parameters
      @query_parameters ||= all_parameters.filter { |p| p['in'] == 'query'}
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

    def build_parameters_json_schema
      parameters = all_parameters
      return unless parameters&.any?

      parameters.each_with_object(new_node) do |parameter, schema|
        params = Rack::Utils.parse_nested_query(parameter['name'])
        generate_schema(schema, params, parameter)
      end
    end

    def build_query_parameters_json_schema
      return unless query_parameters&.any?


    end

    def all_parameters
      parameters = @path_item_object['parameters']&.dup || []
      parameters_on_operation = operation_object['parameters']
      parameters.concat(parameters_on_operation) if parameters_on_operation
      parameters
    end

    def generate_schema(schema, params, parameter)
      required = Set.new(schema['required'])
      params.each do |key, value|
        required << key if parameter['required']
        if value.is_a? Hash
          property_schema = new_node
          generate_schema(property_schema, value, parameter)
          Utils.deep_merge!(schema['properties'], { key => property_schema })
        else
          schema['properties'][key] = parameter['schema']
        end
      end
      schema['required'] = required.to_a
    end

    def new_node
      {
        'type' => 'object',
        'required' => [],
        'properties' => {}
      }
    end
  end
end

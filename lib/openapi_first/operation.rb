# frozen_string_literal: true

require 'forwardable'
require 'json_schemer'
require_relative 'utils'
require_relative 'response_object'

module OpenapiFirst
  class Operation
    extend Forwardable
    def_delegators :@operation,
                   :parameters,
                   :method,
                   :request_body,
                   :operation_id

    WRITE_METHODS = Set.new(%w[post put patch delete]).freeze
    private_constant :WRITE_METHODS

    def initialize(parsed)
      @operation = parsed
    end

    def path
      @operation.path.path
    end

    def read?
      !write?
    end

    def write?
      WRITE_METHODS.include?(method)
    end

    def parameters_json_schema
      @parameters_json_schema ||= build_parameters_json_schema
    end

    def parameters_schema
      @parameters_schema ||= parameters_json_schema && JSONSchemer.schema(parameters_json_schema)
    end

    def content_type_for(status)
      content = response_for(status)['content']
      content.keys[0] if content
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
      media_type['schema']
    end

    def request_body_schema_for(request_content_type)
      content = @operation.request_body.content
      media_type = find_content_for_content_type(content, request_content_type)
      media_type&.fetch('schema', nil)
    end

    def response_for(status)
      @operation.response_by_code(status.to_s, use_default: true).raw
    rescue OasParser::ResponseCodeNotFound
      message = "Response status code or default not found: #{status} for '#{name}'"
      raise OpenapiFirst::ResponseCodeNotFoundError, message
    end

    def name
      "#{method.upcase} #{path} (#{operation_id})"
    end

    private

    def find_content_for_content_type(content, request_content_type)
      content.fetch(request_content_type) do |_|
        type = request_content_type.split(';')[0]
        content[type] || content["#{type.split('/')[0]}/*"] || content['*/*']
      end
    end

    def build_parameters_json_schema
      return unless @operation.parameters&.any?

      @operation.parameters.each_with_object(new_node) do |parameter, schema|
        params = Rack::Utils.parse_nested_query(parameter.name)
        generate_schema(schema, params, parameter)
      end
    end

    def generate_schema(schema, params, parameter) # rubocop:disable Metrics/MethodLength
      required = Set.new(schema['required'])
      params.each do |key, value|
        required << key if parameter.required
        if value.is_a? Hash
          property_schema = new_node
          generate_schema(property_schema, value, parameter)
          Utils.deep_merge!(schema['properties'], { key => property_schema })
        else
          schema['properties'][key] = parameter.schema
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

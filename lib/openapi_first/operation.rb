# frozen_string_literal: true

require 'forwardable'
require_relative 'utils'

module OpenapiFirst
  class Operation
    extend Forwardable
    def_delegators :@operation,
                   :parameters,
                   :method,
                   :request_body,
                   :operation_id

    def initialize(parsed)
      @operation = parsed
    end

    def path
      @operation.path.path
    end

    def parameters_json_schema
      @parameters_json_schema ||= build_parameters_json_schema
    end

    def content_type_for(status)
      content = @operation
                .response_by_code(status.to_s, use_default: true)
                .content
      content.keys[0] if content
    rescue OasParser::ResponseCodeNotFound
      operation_name = "#{method.upcase} #{path}"
      message = "Response status code or default not found: #{status} for '#{operation_name}'" # rubocop:disable Layout/LineLength
      raise OpenapiFirst::ResponseCodeNotFoundError, message
    end

    private

    def build_parameters_json_schema
      return unless @operation.parameters&.any?

      @operation.parameters.each_with_object(new_node) do |parameter, schema|
        params = Rack::Utils.parse_nested_query(parameter.name)
        generate_schema(schema, params, parameter)
      end
    end

    def generate_schema(schema, params, parameter)
      params.each do |key, value|
        schema['required'] << key if parameter.required
        if value.is_a? Hash
          property_schema = new_node
          generate_schema(property_schema, value, parameter)
          Utils.deep_merge!(schema['properties'], { key => property_schema })
        else
          schema['properties'][key] = parameter.schema
        end
      end
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

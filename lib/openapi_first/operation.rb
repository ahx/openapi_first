# frozen_string_literal: true

require 'forwardable'

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

      @operation.parameters.each_with_object(
        'type' => 'object',
        'required' => [],
        'properties' => {}
      ) do |parameter, schema|
        params = Rack::Utils.parse_nested_query(parameter.name)
        generate_schema(schema, params, parameter)
      end
    end

    def generate_schema(schema, params, parameter)
      params.each do |key, value|
        case value
        when Hash
          property_schema = {
            'type' => 'object',
            'required' => parameter.required ? [value.keys.first] : [],
            'properties' => {}
          }
          schema['required'] << key if parameter.required
          generate_schema(property_schema, value, parameter)
          schema['properties'][key] = property_schema
        else
          schema['required'] << parameter.name if parameter.required && value
          schema['properties'][key] = parameter.schema
        end
      end
    end
  end
end

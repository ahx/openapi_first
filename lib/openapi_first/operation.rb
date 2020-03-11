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
    end

    private

    def build_parameters_json_schema
      return unless @operation.parameters&.any?

      @operation.parameters.each_with_object(
        'type' => 'object',
        'required' => [],
        'properties' => {}
      ) do |parameter, schema|
        schema['required'] << parameter.name if parameter.required
        schema['properties'][parameter.name] = parameter.schema
      end
    end
  end
end

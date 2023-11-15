# frozen_string_literal: true

require_relative 'schema'

module OpenapiFirst
  class RequestBody
    def initialize(request_body_object, operation)
      @request_body_object = request_body_object
      @operation = operation
    end

    def description
      @request_body_object['description']
    end

    def required?
      !!@request_body_object['required']
    end

    def schema_for(content_type)
      content = @request_body_object['content']
      return unless content&.any?

      content_schemas&.fetch(content_type) do
        type = content_type.split(';')[0]
        content_schemas[type] || content_schemas["#{type.split('/')[0]}/*"] || content_schemas['*/*']
      end
    end

    private

    def content_schemas
      @content_schemas ||= @request_body_object['content']&.each_with_object({}) do |kv, result|
        type, media_type = kv
        schema_object = media_type['schema']
        next unless schema_object

        result[type] = Schema.new(schema_object, write: @operation.write?,
                                                 openapi_version: @operation.openapi_version)
      end
    end
  end
end

# frozen_string_literal: true

require_relative 'schema'

module OpenapiFirst
  module HasContent
    def schema_for(content_type)
      return unless content&.any?

      content_schemas&.fetch(content_type) do
        type = content_type.split(';')[0]
        content_schemas[type] || content_schemas["#{type.split('/')[0]}/*"] || content_schemas['*/*']
      end
    end

    private

    def content
      raise NotImplementedError
    end

    def schema_write?
      raise NotImplementedError
    end

    def content_schemas
      @content_schemas ||= content&.each_with_object({}) do |kv, result|
        type, media_type = kv
        schema_object = media_type['schema']
        next unless schema_object

        result[type] = Schema.new(schema_object, write: schema_write?,
                                                 openapi_version: @operation.openapi_version)
      end
    end
  end
end

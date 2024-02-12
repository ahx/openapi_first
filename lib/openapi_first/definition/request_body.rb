# frozen_string_literal: true

require_relative '../schema'

module OpenapiFirst
  class Definition
    # Represents a request body definition in the OpenAPI document that belongs to an operation.
    class RequestBody
      def initialize(request_body_object)
        @request_body_object = request_body_object
        freeze
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

        content&.fetch(content_type) do
          type = content_type.split(';')[0]
          content[type] || content["#{type.split('/')[0]}/*"] || content['*/*']
        end&.fetch('schema', nil)
      end
    end
  end
end

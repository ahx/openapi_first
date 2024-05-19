# frozen_string_literal: true

module OpenapiFirst
  class Definition
    # Represents a response definition in the OpenAPI document.
    # This is not a direct reflecton of the OpenAPI 3.X response definition, but a combination of
    # status, content type and content schema.
    class Response
      def initialize(operation:, status:, response_object:, content_type:, content_schema:)
        @operation = operation
        @status = status
        @content_type = content_type
        @content_schema = content_schema
        @headers = response_object['headers']
        @headers_schema = build_headers_schema(response_object['headers'])
      end

      # @attr_reader [Operation] operation The operation this response belongs to.
      # @attr_reader [Integer] status The HTTP status code of the response definition.
      # @attr_reader [String, nil] content_type Content type of this response.
      # @attr_reader [Schema, nil] content_schema the Schema of the response body.
      attr_reader :operation, :status, :content_type, :content_schema, :headers, :headers_schema

      private

      def build_headers_schema(headers_object)
        return unless headers_object&.any?

        properties = {}
        required = []
        headers_object.each do |name, header|
          schema = header['schema']
          next if name.casecmp('content-type').zero?

          properties[name] = schema if schema
          required << name if header['required']
        end
        {
          'properties' => properties,
          'required' => required
        }
      end
    end
  end
end

# frozen_string_literal: true

module OpenapiFirst
  class Definition
    # Represents a response definition in the OpenAPI document.
    # This is not a direct reflecton of the OpenAPI 3.X response definition, but a combination of
    # status, content type and content schema.
    class Response
      def initialize(operation:, status:, response_object:, content_type:, content_schema:)
        @operation = operation
        @response_object = response_object
        @status = status
        @content_type = content_type
        @content_schema = content_schema
      end

      # @attr_reader [Operation] operation The operation this response belongs to.
      # @attr_reader [Integer] status The HTTP status code of the response definition.
      # @attr_reader [String, nil] content_type Content type of this response.
      # @attr_reader [Schema, nil] content_schema the Schema of the response body.
      attr_reader :operation, :status, :content_type, :content_schema

      def headers
        @response_object['headers']
      end

      def description
        @response_object['description']
      end
    end
  end
end

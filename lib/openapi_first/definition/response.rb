# frozen_string_literal: true

module OpenapiFirst
  class Definition
    class Response
      def initialize(operation:, status:, response_object:, content_type:, content_schema:)
        @operation = operation
        @response_object = response_object
        @status = status
        @content_type = content_type
        @content_schema = content_schema
      end

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

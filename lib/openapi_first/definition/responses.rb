# frozen_string_literal: true

require_relative 'response'

module OpenapiFirst
  class Definition
    # @visibility private
    class Responses
      def initialize(operation, responses_object)
        @operation = operation
        @responses_object = responses_object
      end

      def status_defined?(status)
        !!find_response_object(status)
      end

      def response_for(status, response_content_type)
        response_object = find_response_object(status)
        return unless response_object
        return response_without_content(status, response_object) unless content_defined?(response_object)

        defined_content_type = find_defined_content_type(response_object, response_content_type)
        return unless defined_content_type

        content_schema = find_content_schema(response_object, response_content_type)
        Response.new(operation:, status:, response_object:, content_type: defined_content_type, content_schema:)
      end

      private

      attr_reader :openapi_version, :operation

      def response_without_content(status, response_object)
        Response.new(operation:, status:, response_object:, content_type: nil, content_schema: nil)
      end

      def find_defined_content_type(response_object, content_type)
        return if content_type.nil?

        content = response_object['content']
        return content_type if content.key?(content_type)

        type = content_type.split(';')[0]
        return type if content.key?(type)

        key = "#{type.split('/')[0]}/*"
        return key if content.key?(key)

        key = '*/*'
        key if content.key?(key)
      end

      def content_defined?(response_object)
        response_object['content']&.any?
      end

      def find_content_schema(response_object, response_content_type)
        return unless response_content_type

        content_object = find_response_body(response_object['content'], response_content_type)
        content_schema_object = content_object&.fetch('schema', nil)
        return unless content_schema_object

        Schema.new(content_schema_object, write: false, openapi_version: operation.openapi_version)
      end

      def find_response_object(status)
        @responses_object[status.to_s] ||
          @responses_object["#{status / 100}XX"] ||
          @responses_object["#{status / 100}xx"] ||
          @responses_object['default']
      end

      def find_response_body(content, content_type)
        content&.fetch(content_type) do |_|
          type = content_type.split(';')[0]
          content[type] || content["#{type.split('/')[0]}/*"] || content['*/*']
        end
      end
    end
  end
end

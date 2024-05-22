# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  class Definition
    # Represents one request definition derived from operation and requestBody definition
    class Request
      extend Forwardable

      def initialize(operation:, content_type:, content_schema:, required_body:)
        @operation = operation
        @content_type = content_type
        @content_schema = content_schema
        @required_request_body = required_body == true
      end

      def_delegators :@operation, :path_item, :path, :request_method, :path_schema, :query_schema, :cookie_schema,
                     :header_schema, :path_parameters, :query_parameters, :cookie_parameters, :header_parameters

      attr_reader :content_type, :content_schema, :operation

      def required_request_body?
        @required_request_body
      end
    end
  end
end

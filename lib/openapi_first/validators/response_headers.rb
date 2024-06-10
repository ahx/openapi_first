# frozen_string_literal: true

module OpenapiFirst
  module Validators
    class ResponseHeaders
      def self.for(response_definition, openapi_version:)
        schema = response_definition&.headers_schema
        return unless schema

        new(Schema.new(schema, openapi_version:))
      end

      def initialize(schema)
        @schema = schema
      end

      attr_reader :schema

      def call(parsed_request)
        validation = schema.validate(parsed_request.headers)
        Failure.fail!(:invalid_response_header, errors: validation.errors) if validation.error?
      end
    end
  end
end

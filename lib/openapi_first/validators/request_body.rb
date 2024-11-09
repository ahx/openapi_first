# frozen_string_literal: true

module OpenapiFirst
  module Validators
    class RequestBody
      def self.for(request_definition, openapi_version:, hooks: {})
        schema = request_definition.content_schema
        return unless schema

        new(schema, required: request_definition.required_request_body?)
      end

      def initialize(schema, required:)
        @schema = schema
        @required = required
      end

      def call(request)
        request_body = read_body(request)
        if request_body.nil?
          Failure.fail!(:invalid_body, message: 'Request body is not defined') if @required
          return
        end

        validation = Schema::ValidationResult.new(
          @schema.validate(request_body, access_mode: 'write')
        )
        Failure.fail!(:invalid_body, errors: validation.errors) if validation.error?
      end

      private

      def read_body(request)
        request[:body]
      end
    end
  end
end

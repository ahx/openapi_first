# frozen_string_literal: true

require_relative '../response_validation/validator'

module OpenapiFirst
  class Definition
    class RuntimeResponse
      def initialize(operation, rack_response)
        @operation = operation
        @rack_response = rack_response
      end

      def description
        response_definition&.description
      end

      def validate!
        return if @operation.nil?

        ResponseValidation::Validator.new(@operation).validate(@rack_response)
      end

      private

      def status
        response_definition&.status
      end

      def content_schema
        response_definition&.content_schema
      end

      def content_type
        response_definition&.content_type
      end

      def response_definition
        @response_definition ||= @operation.response_for(@rack_response.status, @rack_response.content_type)
      end
    end
  end
end
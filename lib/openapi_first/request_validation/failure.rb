# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    class Failure
      def initialize(status:, location:, message: nil, schema_validation: nil)
        @status = status
        @location = location
        @message = message
        @schema_validation = schema_validation
      end

      attr_reader :status, :request, :location, :schema_validation

      def message
        @message || schema_validation&.message || Rack::Utils::HTTP_STATUS_CODES[status]
      end

      def error_message
        "#{TOPICS.fetch(location)} #{message}"
      end

      TOPICS = {
        body: 'Request body invalid:',
        query: 'Query parameter invalid:',
        header: 'Header parameter invalid:',
        path: 'Path segment invalid:',
        cookie: 'Cookie value invalid:'
      }.freeze
      private_constant :TOPICS
    end
  end
end

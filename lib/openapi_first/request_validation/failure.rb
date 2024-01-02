# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    class Failure
      def initialize(status:, location:, message: nil, validation_result: nil)
        raise ArgumentError, ":location must be one of #{TOPICS.keys}" unless TOPICS.key?(location)

        @status = status
        @location = location
        @message = message
        @validation_result = validation_result
      end

      attr_reader :status, :request, :location, :validation_result

      def message
        @message || validation_result&.message || Rack::Utils::HTTP_STATUS_CODES[status]
      end

      def raise!
        raise NotFoundError, error_message if location == :not_found

        raise RequestInvalidError, error_message
      end

      private

      def error_message
        "#{TOPICS.fetch(location)} #{message}"
      end

      TOPICS = {
        not_found: 'Request not defined.',
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

# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    ## A failure object is returned when a request is invalid.
    # It contains the status code, the location of the error and a message.
    # It can be raised with #raise! to raise an error with a message.
    # @location [Symbol] can be one of :not_found, :body, :query, :header, :path, :cookie
    # @status [Number] is the HTTP status code that fits the failure. This usually is 400, but can be 404, 405 or 415 as well.
    # @message [String] is a generic error message
    # @validation_result [OpenapiFirst::Schema::ValidationResult] is the result of the JSON Schema validation
    class Failure
      TOPICS = {
        not_found: 'Request not defined.',
        body: 'Request body invalid:',
        query: 'Query parameter invalid:',
        header: 'Header parameter invalid:',
        path: 'Path segment invalid:',
        cookie: 'Cookie value invalid:'
      }.freeze
      private_constant :TOPICS

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
    end
  end
end

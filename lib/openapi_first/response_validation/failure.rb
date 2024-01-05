# frozen_string_literal: true

module OpenapiFirst
  module ResponseValidation
    ## A failure object which is returned when a response is invalid.

    class Failure
      TYPES = {
        response_not_found: 'Response is not defined.',
        invalid_response_body: 'Response body is invalid:',
        invalid_response_header: 'Response header is invalid:'
      }.freeze
      private_constant :TYPES

      # @param type [Symbol] See TYPES.keys
      # @param message [String] A generic error message
      # @param errors [Array<OpenapiFirst::Schema::ValidationError>]
      def initialize(error_type, message: nil, errors: nil)
        unless TYPES.key?(error_type)
          raise ArgumentError,
                "error_type must be one of #{TYPES.keys}, but was #{error_type.inspect}"
        end

        @error_type = error_type
        @message = message
        @errors = errors
      end

      attr_reader :error_type, :message, :errors

      # Raise an exception that fits the failure.
      def raise!
        raise ResponseNotFoundError, exception_message if error_type == :response_not_found

        raise ResponseInvalidError, exception_message
      end

      private

      def exception_message
        "#{TYPES.fetch(error_type)} #{@message || errors&.map(&:error)&.join('. ')}"
      end
    end
  end
end

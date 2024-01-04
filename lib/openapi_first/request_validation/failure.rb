# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    ## A failure object which is returned when a request is invalid.
    class Failure
      TYPES = {
        not_found: 'Request path is not defined.',
        method_not_allowed: 'Request method is not defined.',
        unsupported_media_type: 'Request content type is not defined.',
        invalid_body: 'Request body invalid:',
        invalid_query: 'Query parameter invalid:',
        invalid_header: 'Header parameter invalid:',
        invalid_path: 'Path segment invalid:',
        invalid_cookie: 'Cookie value invalid:'
      }.freeze
      private_constant :TYPES

      # @param type [Symbol] See TYPES.keys
      # @param message [String] A generic error message
      # @param errors [Array<OpenapiFirst::Schema::ValidationError>]
      def initialize(error_type, message: nil, errors: nil)
        raise ArgumentError, "error_type must be one of #{TYPES.keys}" unless TYPES.key?(error_type)

        @error_type = error_type
        @message = message
        @errors = errors
      end

      attr_reader :error_type, :message, :errors

      # Raise an exception that fits the failure.
      def raise!
        raise NotFoundError, exception_message if error_type == :not_found

        raise RequestInvalidError, exception_message
      end

      private

      def exception_message
        "#{TYPES.fetch(error_type)} #{@message || errors&.map(&:error)&.join('. ')}"
      end
    end
  end
end

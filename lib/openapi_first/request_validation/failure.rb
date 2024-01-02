# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    ## A failure object which is returned when a request is invalid.
    # @type [Symbol] can be one of :not_found, :body, :query, :header, :path, :cookie
    # @status [Number] is the HTTP status code that fits the failure.
    #         This usually is 400, but can be 404, 405 or 415 as well.
    # @message [String] is a generic error message
    # @validation_result [OpenapiFirst::Schema::ValidationResult] is the result of the JSON Schema validation
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

      def initialize(error_type, message: nil, validation_result: nil)
        raise ArgumentError, "error_type must be one of #{TYPES.keys}" unless TYPES.key?(error_type)

        @error_type = error_type
        @message = message
        @validation_result = validation_result
      end

      attr_reader :request, :error_type, :validation_result

      # Raise an exception that fits the failure.
      def raise!
        raise NotFoundError, error_message if error_type == :not_found

        raise RequestInvalidError, error_message
      end

      private

      def error_message
        "#{TYPES.fetch(error_type)} #{@message || validation_result&.message}"
      end
    end
  end
end

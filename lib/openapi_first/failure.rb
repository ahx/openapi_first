# frozen_string_literal: true

module OpenapiFirst
  # A failure object returned when validation or parsing of a request or response has failed.
  # This returned in ValidatedRequest#error and ValidatedResponse#error.
  class Failure < Data.define(:type, :message, :errors)
    TYPES = {
      not_found: [NotFoundError, 'Not found.'],
      method_not_allowed: [RequestInvalidError, 'Request method is not defined.'],
      unsupported_media_type: [RequestInvalidError, 'Request content type is not defined.'],
      invalid_body: [RequestInvalidError, 'Request body invalid:'],
      invalid_query: [RequestInvalidError, 'Query parameter is invalid:'],
      invalid_header: [RequestInvalidError, 'Request header is invalid:'],
      invalid_path: [RequestInvalidError, 'Path segment is invalid:'],
      invalid_cookie: [RequestInvalidError, 'Cookie value is invalid:'],
      response_content_type_not_found: [ResponseNotFoundError],
      response_status_not_found: [ResponseNotFoundError],
      invalid_response_body: [ResponseInvalidError, 'Response body is invalid:'],
      invalid_response_header: [ResponseInvalidError, 'Response header is invalid:']
    }.freeze
    private_constant :TYPES

    # Marks the current request as invalid with a new Failure and stops validation.
    # Call this only inside a `before_request_validation` or `after_request_validation` hook or in
    # the block passed to {Definition#validate_request}. It uses `throw`, which nothing else catches.
    # @example
    #   config.before_request_validation do |rack_request, request_definition|
    #     OpenapiFirst::Failure.fail!(:not_found) unless request_definition.operation['x-public']
    #   end
    # @param type [Symbol] One of :not_found, :method_not_allowed, :unsupported_media_type,
    #   :invalid_body, :invalid_query, :invalid_header, :invalid_path, :invalid_cookie
    # @param message [String, nil] The error message
    # @param errors [Array<OpenapiFirst::Schema::ValidationError>, nil]
    # @return [void]
    def self.fail!(type, message: nil, errors: nil)
      throw FAILURE, new(
        type,
        message:,
        errors:
      )
    end

    # @param type [Symbol] One of :not_found, :method_not_allowed, :unsupported_media_type,
    #   :invalid_body, :invalid_query, :invalid_header, :invalid_path, :invalid_cookie,
    #   :response_content_type_not_found, :response_status_not_found, :invalid_response_body,
    #   :invalid_response_header
    # @param message [String] A generic error message
    # @raise [ArgumentError] if type is unknown
    # @param errors [Array<OpenapiFirst::Schema::ValidationError>]
    def self.new(type, message: nil, errors: nil)
      unless TYPES.key?(type)
        raise ArgumentError,
              "type must be one of #{TYPES.keys} but was #{type.inspect}"
      end
      super(type:, message:, errors:)
    end

    # @!attribute [r] type
    #   @return [Symbol] The type of the failure, e.g. :invalid_body. See {.new} for all types.

    # @!attribute [r] errors
    #   @return [Array<OpenapiFirst::Schema::ValidationError>, nil] Schema validation errors

    alias original_message message
    private :original_message

    def inspect
      "#<OpenapiFirst::Failure:#{object_id} type: #{type}, message: #{message}>"
    end

    # The message passed to {.new}, or {#exception_message} if none was passed
    # @return [String]
    def message
      original_message || exception_message
    end

    # @param context [ValidatedRequest, ValidatedResponse, nil] The object that failed validation
    # @return [RequestInvalidError, NotFoundError, ResponseInvalidError, ResponseNotFoundError]
    #   The exception to raise for this failure type
    def exception(context = nil)
      TYPES.fetch(type).first.new(exception_message, context)
    end

    # @return [String] The message of {#exception}, prefixed by the failure type, e.g. "Request body invalid: ..."
    def exception_message
      _, message_prefix = TYPES.fetch(type)

      [message_prefix, original_message || generate_message].compact.join(' ')
    end

    private

    def generate_message
      messages = errors&.take(3)&.map(&:message)
      messages << "... (#{errors.size} errors total)" if errors && errors.size > 3
      messages&.join('. ')
    end
  end
end

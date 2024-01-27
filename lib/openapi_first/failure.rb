# frozen_string_literal: true

module OpenapiFirst
  # A failure object returned when validation of request or response has failed.
  class Failure
    FAILURE = :openapi_first_validation_failure

    TYPES = {
      not_found: [NotFoundError, 'Request path is not defined.'],
      method_not_allowed: [RequestInvalidError, 'Request method is not defined.'],
      unsupported_media_type: [RequestInvalidError, 'Request content type is not defined.'],
      invalid_body: [RequestInvalidError, 'Request body invalid:'],
      invalid_query: [RequestInvalidError, 'Query parameter is invalid:'],
      invalid_header: [RequestInvalidError, 'Request header is invalid:'],
      invalid_path: [RequestInvalidError, 'Path segment is invalid:'],
      invalid_cookie: [RequestInvalidError, 'Cookie value is invalid:'],
      response_not_found: [ResponseNotFoundError, 'Response is not defined.'],
      invalid_response_body: [ResponseInvalidError, 'Response body is invalid:'],
      invalid_response_header: [ResponseInvalidError, 'Response header is invalid:']
    }.freeze
    private_constant :TYPES

    # @param error_type [Symbol] See Failure::TYPES.keys
    # @param errors [Array<OpenapiFirst::Schema::ValidationError>]
    def self.fail!(error_type, message: nil, errors: nil)
      throw FAILURE, new(
        error_type,
        message:,
        errors:
      )
    end

    # @param error_type [Symbol] See TYPES.keys
    # @param message [String] A generic error message
    # @param errors [Array<OpenapiFirst::Schema::ValidationError>]
    def initialize(error_type, message: nil, errors: nil)
      unless TYPES.key?(error_type)
        raise ArgumentError,
              "error_type must be one of #{TYPES.keys} but was #{error_type.inspect}"
      end

      @error_type = error_type
      @message = message
      @errors = errors
    end

    attr_reader :error_type, :message, :errors
    alias type error_type

    # Raise an exception that fits the failure.
    def raise!
      exception, = TYPES.fetch(error_type)
      raise exception, exception_message
    end

    def exception_message
      _, message_prefix = TYPES.fetch(error_type)

      "#{message_prefix} #{@message || generate_message}"
    end

    private

    def generate_message
      messages = errors&.take(4)&.map(&:error)
      messages << "... (#{errors.size} errors total)" if errors && errors.size > 4
      messages&.join('. ')
    end
  end
end

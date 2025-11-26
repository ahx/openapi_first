# frozen_string_literal: true

module OpenapiFirst
  # A failure object returned when validation or parsing of a request or response has failed.
  # This returned in ValidatedRequest#error and ValidatedResponse#error.
  class Failure < Data.define(:type, :message, :errors) # rubocop:disable Style/DataInheritance
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

    # @param type [Symbol] See Failure::TYPES.keys
    # @param errors [Array<OpenapiFirst::Schema::ValidationError>]
    def self.fail!(type, message: nil, errors: nil)
      throw FAILURE, new(
        type,
        message:,
        errors:
      )
    end

    # @param type [Symbol] See TYPES.keys
    # @param message [String] A generic error message
    # @param errors [Array<OpenapiFirst::Schema::ValidationError>]
    def self.new(type, message: nil, errors: nil)
      unless TYPES.key?(type)
        raise ArgumentError,
              "type must be one of #{TYPES.keys} but was #{type.inspect}"
      end
      super(type:, message:, errors:)
    end

    # @method type [Symbol] type The type of the failure. See TYPES.keys.
    # Example: :invalid_body

    # @method errors [Array<OpenapiFirst::Schema::ValidationError>, nil] errors Schema validation errors

    alias original_message message
    private :original_message

    # A generic error message
    def message
      original_message || exception_message
    end

    def exception(context = nil)
      TYPES.fetch(type).first.new(exception_message, context)
    end

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

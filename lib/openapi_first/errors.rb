# frozen_string_literal: true

module OpenapiFirst
  class Error < StandardError; end

  class NotFoundError < Error; end

  class ResponseInvalid < Error; end

  class ResponseCodeNotFoundError < ResponseInvalid; end

  class ResponseContentTypeNotFoundError < ResponseInvalid; end

  class ResponseBodyInvalidError < ResponseInvalid; end

  class ResponseHeaderInvalidError < ResponseInvalid; end

  class BodyParsingError < Error; end

  class RequestInvalidError < Error
    def initialize(error)
      @location = error[:location]
      title, validation_errors = error.values_at(:title, :validation_errors)
      if validation_errors
        super build_error_message(validation_errors)
      else
        super title
      end
    end

    private

    attr_reader :location

    def build_error_message(validation_errors)
      validation_errors.map do |error|
        [
          TOPICS[location],
          pointer(error['data_pointer']),
          ErrorFormat.error_details(error)[:title]
        ].compact.join(' ')
      end.join(', ')
    end

    TOPICS = {
      content: 'Request body invalid:',
      query: 'Query parameter invalid:',
      header: 'Header parameter invalid:',
      path: 'Path segment invalid:',
      cookie: 'Cookie value invalid:'
    }.freeze
    private_constant :TOPICS

    def pointer(data_pointer)
      return if data_pointer.nil? || data_pointer.empty?
      return data_pointer if location == :content

      data_pointer&.delete_prefix('/')
    end
  end
end

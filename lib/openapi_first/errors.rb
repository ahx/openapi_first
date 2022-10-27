# frozen_string_literal: true

module OpenapiFirst
  class Error < StandardError; end

  class NotFoundError < Error; end

  class HandlerNotFoundError < Error; end

  class NotImplementedError < Error
    def initialize(message)
      warn 'NotImplementedError is deprecated. Handle HandlerNotFoundError instead'
      super
    end
  end

  class ResponseInvalid < Error; end

  class ResponseCodeNotFoundError < ResponseInvalid; end

  class ResponseContentTypeNotFoundError < ResponseInvalid; end

  class ResponseBodyInvalidError < ResponseInvalid; end

  class RequestInvalidError < Error
    def initialize(serialized_errors)
      message = error_message(serialized_errors)
      super message
    end

    private

    def error_message(errors)
      errors.map do |error|
        [human_source(error), human_error(error)].compact.join(' ')
      end.join(', ')
    end

    def human_source(error)
      return unless error[:source]

      source_key = error[:source].keys.first
      source = {
        pointer: 'Request body invalid:',
        parameter: 'Query parameter invalid:'
      }.fetch(source_key, source_key)
      name = error[:source].values.first
      source += " #{name}" unless name.nil? || name.empty?
      source
    end

    def human_error(error)
      error[:title]
    end
  end
end

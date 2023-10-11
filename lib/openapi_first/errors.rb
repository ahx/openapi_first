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

  class RequestInvalidError < Error; end
end

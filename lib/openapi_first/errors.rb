# frozen_string_literal: true

module OpenapiFirst
  class Error < StandardError; end
  class NotFoundError < Error; end
  class RequestInvalidError < Error; end
  class ResponseInvalidError < Error; end
  class ResponseCodeNotFoundError < ResponseInvalidError; end
  class ResponseContentTypeNotFoundError < ResponseInvalidError; end
  class ResponseHeaderInvalidError < ResponseInvalidError; end
  class ResponseBodyInvalidError < ResponseInvalidError; end
end

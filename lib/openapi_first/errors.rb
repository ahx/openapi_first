# frozen_string_literal: true

module OpenapiFirst
  class NotFoundError < StandardError; end
  class RequestInvalidError < StandardError; end
  class ResponseInvalidError < StandardError; end
  class ResponseCodeNotFoundError < ResponseInvalidError; end
  class ResponseContentTypeNotFoundError < ResponseInvalidError; end
  class ResponseHeaderInvalidError < ResponseInvalidError; end
  class ResponseBodyInvalidError < ResponseInvalidError; end
end

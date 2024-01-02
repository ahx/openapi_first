# frozen_string_literal: true

module OpenapiFirst
  class NotFoundError < StandardError; end
  class RequestInvalidError < StandardError; end
  class ResponseInvalid < StandardError; end
  class ResponseCodeNotFoundError < ResponseInvalid; end
  class ResponseContentTypeNotFoundError < ResponseInvalid; end
  class ResponseHeaderInvalidError < ResponseInvalid; end
  class ResponseBodyInvalidError < ResponseInvalid; end
end

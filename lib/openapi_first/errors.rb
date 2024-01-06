# frozen_string_literal: true

module OpenapiFirst
  class Error < StandardError; end
  class NotFoundError < Error; end
  class RequestInvalidError < Error; end
  class ResponseNotFoundError < Error; end
  class ResponseInvalidError < Error; end
end

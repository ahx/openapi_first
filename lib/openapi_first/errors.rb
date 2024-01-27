# frozen_string_literal: true

module OpenapiFirst
  # @!visibility private
  class Error < StandardError; end
  # @!visibility private
  class ParseError < Error; end
  # @!visibility private
  class NotFoundError < Error; end
  # @!visibility private
  class RequestInvalidError < Error; end
  # @!visibility private
  class ResponseNotFoundError < Error; end
  # @!visibility private
  class ResponseInvalidError < Error; end
end

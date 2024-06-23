# frozen_string_literal: true

module OpenapiFirst
  # @!visibility private
  class Error < StandardError; end
  # @!visibility private
  class FileNotFoundError < Error; end
  # @!visibility private
  class ParseError < Error; end

  # @!visibility private
  class RequestInvalidError < Error
    def initialize(message, validated_request)
      super(message)
      @request = validated_request
    end

    # @attr_reader [OpenapiFirst::ValidatedRequest] request The validated request
    attr_reader :request
  end

  # @!visibility private
  class NotFoundError < RequestInvalidError; end

  # @!visibility private
  class ResponseInvalidError < Error
    def initialize(message, validated_response)
      super(message)
      @response = validated_response
    end

    # @attr_reader [OpenapiFirst::ValidatedResponse] request The validated response
    attr_reader :response
  end

  # @!visibility private
  class ResponseNotFoundError < ResponseInvalidError; end
end

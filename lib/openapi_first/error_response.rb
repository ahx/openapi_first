# frozen_string_literal: true

module OpenapiFirst
  # Include this module to build an error response for the request validation middleware.
  # Implement {#body} and {#content_type}; override {#status} or {#render} if needed.
  # Register it via {OpenapiFirst.register_error_response} to refer to it by name.
  # @example
  #   class MyErrorResponse
  #     include OpenapiFirst::ErrorResponse
  #
  #     def body = JSON.generate({ error: failure.message })
  #     def content_type = 'application/json'
  #   end
  module ErrorResponse
    # @param failure [OpenapiFirst::Failure]
    def initialize(failure: nil)
      @failure = failure
    end

    # @return [OpenapiFirst::Failure] The reason why the request is invalid
    attr_reader :failure

    # The response body
    # @return [String]
    def body
      raise "#{self.class} must implement the method #{__method__}"
    end

    # The response content-type
    # @return [String]
    def content_type
      raise "#{self.class} must implement the method #{__method__}"
    end

    STATUS = {
      not_found: 404,
      method_not_allowed: 405,
      unsupported_media_type: 415
    }.freeze
    private_constant :STATUS

    # The response status: 404 for :not_found, 405 for :method_not_allowed, 415 for
    # :unsupported_media_type, otherwise 400
    # @return [Integer]
    def status
      STATUS[failure.type] || 400
    end

    # Render this error response
    # @return [Array] A Rack response triplet
    def render
      Rack::Response.new(body, status, Rack::CONTENT_TYPE => content_type).finish
    end
  end
end

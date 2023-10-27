# frozen_string_literal: true

module OpenapiFirst
  # This is the base class for error responses
  class ErrorResponse
    ## @param status [Integer] The intended HTTP status code.
    ## @param message [String] A descriptive error message.
    ## @param location [Symbol] The location of the error (:body, :query, :header, :cookie, :path).
    ## @param validation_result [ValidationResult]
    def initialize(status:, location:, message:, validation_result:)
      @status = status
      @message = message
      @location = location
      @validation_output = validation_result&.output
      @schema = validation_result&.schema
      @data = validation_result&.data
    end

    attr_reader :status, :location, :message, :schema, :data, :validation_output

    def render
      Rack::Response.new(body, status, Rack::CONTENT_TYPE => content_type).finish
    end

    def content_type = 'application/json'

    def body
      raise NotImplementedError
    end
  end
end

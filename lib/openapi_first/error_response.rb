# frozen_string_literal: true

module OpenapiFirst
  # This is the base class for error responses
  class ErrorResponse
    def self.throw!(status, location = nil, title: nil, validation_result: nil)
      throw :error, {
        status:,
        location:,
        title: title || validation_result&.output&.fetch('error') || Rack::Utils::HTTP_STATUS_CODES[status],
        validation_result:
      }
    end

    ## @param status [Integer] The HTTP status code.
    ## @param title [String] The title of the error. Usually the name of the HTTP status code.
    ## @param location [Symbol] The location of the error (:request_body, :query, :header, :cookie, :path).
    ## @param validation_result [ValidationResult]
    def initialize(status:, location:, title:, validation_result:)
      @status = status
      @title = title
      @location = location
      @validation_output = validation_result&.output
      @schema = validation_result&.schema
      @data = validation_result&.data
    end

    attr_reader :status, :location, :title, :schema, :data, :validation_output

    def render
      Rack::Response.new(body, status, Rack::CONTENT_TYPE => content_type).finish
    end

    def content_type = 'application/json'

    def body
      raise NotImplementedError
    end
  end
end

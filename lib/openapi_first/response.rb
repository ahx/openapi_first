# frozen_string_literal: true

require_relative 'response_parser'
require_relative 'response_validator'
require_relative 'validated_response'

module OpenapiFirst
  # Represents a response definition in the OpenAPI document.
  # This is not a direct reflecton of the OpenAPI 3.X response definition, but a combination of
  # status, content type and content schema.
  class Response
    def initialize(status:, headers:, headers_schema:, content_type:, content_schema:)
      @status = status
      @content_type = content_type
      @content_schema = content_schema
      @headers = headers
      @headers_schema = headers_schema
      @parser = ResponseParser.new(headers:, content_type:)
      @validator = ResponseValidator.new(self)
    end

    # @attr_reader [Integer] status The HTTP status code of the response definition.
    # @attr_reader [String, nil] content_type Content type of this response.
    # @attr_reader [Schema, nil] content_schema the Schema of the response body.
    attr_reader :status, :content_type, :content_schema, :headers, :headers_schema

    def validate(response)
      parsed_values = @parser.parse(response)
      error = @validator.call(parsed_values)
      ValidatedResponse.new(response, parsed_values:, error:, response_definition: self)
    end

    private

    def parse(request)
      @parser.parse(request)
    end
  end
end

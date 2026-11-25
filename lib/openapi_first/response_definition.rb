# frozen_string_literal: true

require_relative 'response_parser'
require_relative 'response_validator'
require_relative 'validated_response'

module OpenapiFirst
  # Represents a response definition in the OpenAPI document.
  # This is not a direct reflecton of the OpenAPI 3.X response definition, but a combination of
  # status, content type and content schema.
  class ResponseDefinition
    # @api private
    def initialize(status:, headers:, content_type:, content_schema:, key:)
      @status = status
      @content_type = content_type
      @content_schema = content_schema
      @headers = headers
      @key = key
      @parser = ResponseParser.new(headers:, content_type:)
      @validator = ResponseValidator.new(content_schema:, headers:)
    end

    # @!attribute [r] status
    #   @return [String] The status as written in the API description, e.g. "200", "4XX" or "default"
    # @!attribute [r] content_type
    #   @return [String, nil] Content type of this response
    # @!attribute [r] content_schema
    #   @return [#value, nil] The schema of the response body. Its `value` is the JSON Schema Hash.
    # @!attribute [r] headers
    #   @return [Array<ResponseHeader>, nil] The response headers defined in the API description
    # @!attribute [r] key
    #   @return [String] A unique key of this response definition
    attr_reader :status, :content_type, :content_schema, :headers, :key

    # Validates a response against this response definition.
    # @param response [Rack::Response]
    # @return [ValidatedResponse]
    def validate(response)
      parsed_values, error = @parser.parse(response)
      error ||= @validator.call(parsed_values) if parsed_values
      ValidatedResponse.new(response, parsed_values:, error:, response_definition: self)
    end
  end

  # @deprecated Use {ResponseDefinition}
  Response = ResponseDefinition
  deprecate_constant :Response
end

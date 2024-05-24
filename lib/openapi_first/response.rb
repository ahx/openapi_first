# frozen_string_literal: true

require_relative 'response_parser'
require_relative 'response_validation/validator'
require_relative 'validated_response'

module OpenapiFirst
  # Represents a response definition in the OpenAPI document.
  # This is not a direct reflecton of the OpenAPI 3.X response definition, but a combination of
  # status, content type and content schema.
  class Response
    def initialize(status:, response_object:, content_type:, content_schema:)
      @status = status
      @content_type = content_type
      @content_schema = content_schema
      @headers = response_object['headers']
      @headers_schema = build_headers_schema(response_object['headers'])
      @parser = ResponseParser.new(headers: response_object['headers'], content_type:)
      @validator = ResponseValidation::Validator.new(self, openapi_version: '3.1')
    end

    # @attr_reader [Integer] status The HTTP status code of the response definition.
    # @attr_reader [String, nil] content_type Content type of this response.
    # @attr_reader [Schema, nil] content_schema the Schema of the response body.
    attr_reader :status, :content_type, :content_schema, :headers, :headers_schema

    def validate(response)
      parsed = @parser.parse(response)
      error = @validator.call(parsed)
      ValidatedResponse.new(parsed, error)
    end

    private

    def parse(request)
      @parser.parse(request)
    end

    def build_headers_schema(headers_object)
      return unless headers_object&.any?

      properties = {}
      required = []
      headers_object.each do |name, header|
        schema = header['schema']
        next if name.casecmp('content-type').zero?

        properties[name] = schema if schema
        required << name if header['required']
      end
      {
        'properties' => properties,
        'required' => required
      }
    end
  end
end

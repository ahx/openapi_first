# frozen_string_literal: true

require 'forwardable'
require_relative 'request_parser'
require_relative 'request_validator'
require_relative 'validated_request'

module OpenapiFirst
  # Represents one request definition derived from operation and requestBody definition
  class Request
    extend Forwardable

    def initialize(operation:, content_type:, content_schema:, required_body:, hooks:, openapi_version:)
      @operation = operation
      @content_type = content_type
      @content_schema = content_schema
      @required_request_body = required_body == true
      @parser = RequestParser.new(
        query_parameters: operation.query_parameters,
        path_parameters: operation.path_parameters,
        header_parameters: operation.header_parameters,
        cookie_parameters: operation.cookie_parameters
      )
      @validator = RequestValidator.new(self, hooks:, openapi_version:)
    end

    def_delegators :@operation, :path_item, :path, :request_method, :path_schema, :query_schema, :cookie_schema,
                   :header_schema, :path_parameters, :query_parameters, :cookie_parameters, :header_parameters

    attr_reader :content_type, :content_schema, :operation

    def validate(request, route_params:)
      parsed = @parser.parse(request, route_params:)
      error = @validator.call(parsed)
      ValidatedRequest.new(parsed, error:, request_definition: self)
    end

    def required_request_body?
      @required_request_body
    end
  end
end

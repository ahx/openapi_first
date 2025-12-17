# frozen_string_literal: true

require 'openapi_parameters'
require_relative 'parsed_request'
require_relative 'request_validator'
require_relative 'validated_request'
require_relative 'request_body_parsers'

module OpenapiFirst
  # Represents one request definition of an OpenAPI description.
  # Note that this is not the same as an OpenAPI 3.x Operation.
  # An 3.x Operation object can accept multiple requests, because it can handle multiple content-types.
  # This class represents one of those requests.
  class Request
    def initialize(path:, request_method:, operation_object:, # rubocop:disable Metrics/MethodLength
                   parameters:, content_type:, content_schema:, required_body:, key:)
      @path = path
      @request_method = request_method
      @content_type = content_type
      @content_schema = content_schema
      @operation = operation_object
      @allow_empty_content = content_type.nil? || required_body == false
      @key = key
      @query_parser = parameters.query&.then { |params| OpenapiParameters::Query.new(params) }
      @path_parser = parameters.path&.then { |params| OpenapiParameters::Path.new(params) }
      @headers_parser = parameters.header&.then { |params| OpenapiParameters::Header.new(params) }
      @cookies_parser = parameters.cookie&.then { |params| OpenapiParameters::Cookie.new(params) }
      @body_parsers = RequestBodyParsers[content_type] if content_type
      @validator = RequestValidator.new(
        content_schema:,
        required_request_body: required_body == true,
        path_schema: parameters.path_schema,
        query_schema: parameters.query_schema,
        header_schema: parameters.header_schema,
        cookie_schema: parameters.cookie_schema
      )
      @parameters = parameters
    end

    attr_reader :content_type, :content_schema, :operation, :request_method, :path, :key, :query_schema, :parameters
    private attr_reader :query_parser

    def allow_empty_content?
      @allow_empty_content
    end

    def validate(request, route_params:)
      parsed_request = nil
      error = catch FAILURE do
        parsed_request = parse_request(request, route_params:)
        @validator.call(parsed_request)
        nil
      end
      ValidatedRequest.new(request, parsed_request:, error:, request_definition: self, query_parser:)
    end

    def operation_id
      @operation['operationId']
    end

    private

    def parse_request(request, route_params:)
      ParsedRequest.new(
        path: @path_parser&.unpack(route_params),
        query: parse_query(request.env[Rack::QUERY_STRING]),
        headers: @headers_parser&.unpack_env(request.env),
        cookies: @cookies_parser&.unpack(request.env[Rack::HTTP_COOKIE]),
        body: @body_parsers&.call(request)
      )
    end

    def parse_query(query_string)
      @query_parser&.unpack(query_string)
    rescue OpenapiParameters::InvalidParameterError
      Failure.fail!(:invalid_query, message: 'Invalid query parameter.')
    end
  end
end

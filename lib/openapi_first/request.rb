# frozen_string_literal: true

require_relative 'parameters'
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
    def initialize(path:, request_method:, operation_object:, # rubocop:disable Metrics/ParameterLists
                   parameters:, content_type:, content_schema:, required_body:, key:, encoding: nil)
      @path = path
      @request_method = request_method
      @content_type = content_type
      @content_schema = content_schema
      @operation = operation_object
      @allow_empty_content = content_type.nil? || required_body == false
      @key = key
      @query_parser = parameters.query_parser
      @path_parser = parameters.path_parser
      @header_parser = parameters.header_parser
      @cookie_parser = parameters.cookie_parser
      @body_parsers = build_body_parser(content_type, encoding) if content_type
      @validator = RequestValidator.new(
        content_schema:,
        content_type:,
        required_request_body: required_body == true,
        path_schema: parameters.path_schema,
        query_schema: parameters.query_schema,
        header_schema: parameters.header_schema,
        cookie_schema: parameters.cookie_schema
      )
    end

    attr_reader :content_type, :content_schema, :operation, :request_method, :path, :key
    private attr_reader :query_parser

    def allow_empty_content?
      @allow_empty_content
    end

    def validate(request, route_params:)
      parsed_request, error = parse_request(request, route_params:)
      error ||= @validator.call(parsed_request) if parsed_request
      ValidatedRequest.new(request, parsed_request:, error:, request_definition: self, query_parser:)
    end

    def operation_id
      @operation['operationId']
    end

    private

    def parse_request(request, route_params:)
      query, query_error = parse_query(request.env[Rack::QUERY_STRING])
      return [nil, query_error] if query_error

      body = @body_parsers&.call(request)
      return [nil, body] if body.is_a?(Failure)

      [ParsedRequest.new(
        path: @path_parser&.unpack(route_params),
        query:,
        headers: @header_parser&.unpack(Parameters::HeadersHash.new(request.env)),
        cookies: @cookie_parser&.unpack(Rack::Utils.parse_cookies_header(request.env[Rack::HTTP_COOKIE])),
        body:
      ), nil]
    end

    def parse_query(query_string)
      [@query_parser&.unpack(query_string), nil]
    rescue Rack::Utils::InvalidParameterError
      [nil, Failure.new(:invalid_query, message: 'Invalid query parameter.')]
    end

    def build_body_parser(content_type, encoding)
      RequestBodyParsers[content_type, { encoding: encoding || {} }]
    end
  end
end

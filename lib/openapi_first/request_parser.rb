# frozen_string_literal: true

require 'openapi_parameters'
require_relative 'request_body_parsers'

module OpenapiFirst
  ParsedRequest = Data.define(:path, :query, :headers, :body, :cookies)

  # Parse a request
  class RequestParser
    def initialize(
      query_parameters:,
      path_parameters:,
      header_parameters:,
      cookie_parameters:,
      content_type:
    )
      @query_parser = OpenapiParameters::Query.new(query_parameters) if query_parameters
      @path_parser = OpenapiParameters::Path.new(path_parameters) if path_parameters
      @headers_parser = OpenapiParameters::Header.new(header_parameters) if header_parameters
      @cookies_parser = OpenapiParameters::Cookie.new(cookie_parameters) if cookie_parameters
      @body_parsers = RequestBodyParsers[content_type] if content_type
    end

    attr_reader :query, :path, :headers, :cookies

    def parse(request, route_params:)
      ParsedRequest.new(
        path: @path_parser&.unpack(route_params),
        query: @query_parser&.unpack(request.env[Rack::QUERY_STRING]),
        headers: @headers_parser&.unpack_env(request.env),
        cookies: @cookies_parser&.unpack(request.env[Rack::HTTP_COOKIE]),
        body: @body_parsers&.call(request)
      )
    end
  end
end

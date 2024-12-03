# frozen_string_literal: true

require 'openapi_parameters'
require_relative 'body_parser'

module OpenapiFirst
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
      @body_parser = BodyParser[content_type] if content_type
    end

    attr_reader :query, :path, :headers, :cookies

    def parse(request, route_params:)
      result = {}
      result[:path] = @path_parser.unpack(route_params) if @path_parser
      result[:query] = @query_parser.unpack(request.env[Rack::QUERY_STRING]) if @query_parser
      result[:headers] = @headers_parser.unpack_env(request.env) if @headers_parser
      result[:cookies] = @cookies_parser.unpack(request.env[Rack::HTTP_COOKIE]) if @cookies_parser
      result[:body] = @body_parser.call(request) if @body_parser
      result
    end
  end
end

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
      content_type:,
      encoding: nil
    )
      @query_parser = OpenapiParameters::Query.new(query_parameters) if query_parameters
      @path_parser = OpenapiParameters::Path.new(path_parameters) if path_parameters
      @headers_parser = OpenapiParameters::Header.new(header_parameters) if header_parameters
      @cookies_parser = OpenapiParameters::Cookie.new(cookie_parameters) if cookie_parameters
      @body_parsers = RequestBodyParsers[content_type] if content_type
      @encoding = encoding
    end

    attr_reader :query, :path, :headers, :cookies

    def parse(request, route_params:)
      ParsedRequest.new(
        path: @path_parser&.unpack(route_params),
        query: parse_query(request.env[Rack::QUERY_STRING]),
        headers: @headers_parser&.unpack_env(request.env),
        cookies: @cookies_parser&.unpack(request.env[Rack::HTTP_COOKIE]),
        body: parse_body(request)
      )
    end

    private

    def parse_body(request)
      return unless @body_parsers

      # Use encoding-aware parsing for multipart requests when encoding is specified
      if @encoding && @body_parsers == RequestBodyParsers::MultipartBodyParser
        @body_parsers.call_with_encoding(request, @encoding)
      else
        @body_parsers.call(request)
      end
    end

    def parse_query(query_string)
      @query_parser&.unpack(query_string)
    rescue OpenapiParameters::InvalidParameterError
      Failure.fail!(:invalid_query, message: 'Invalid query parameter.')
    end
  end
end

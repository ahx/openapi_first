# frozen_string_literal: true

require 'openapi_parameters'
require_relative 'parsed_request'

module OpenapiFirst
  # Parse a request
  class RequestParser
    def initialize(
      query_parameters:,
      path_parameters:,
      header_parameters:,
      cookie_parameters:
    )
      @query = OpenapiParameters::Query.new(query_parameters) if query_parameters
      @path = OpenapiParameters::Path.new(path_parameters) if path_parameters
      @headers = OpenapiParameters::Header.new(header_parameters) if header_parameters
      @cookies = OpenapiParameters::Cookie.new(cookie_parameters) if cookie_parameters
    end

    attr_reader :query, :path, :headers, :cookies

    def parse(request, route_params:)
      ParsedRequest.new(request, parsers: self, route_params:)
    end
  end
end

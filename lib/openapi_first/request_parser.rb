# frozen_string_literal: true

require 'openapi_parameters'
require_relative 'parsed_request'

module OpenapiFirst
  class RequestParser
    def initialize(operation)
      parameters = operation.query_parameters
      @query = OpenapiParameters::Query.new(operation.query_parameters) if parameters

      parameters = operation.path_parameters
      @path = OpenapiParameters::Path.new(parameters) if parameters

      parameters = operation.header_parameters
      @headers = OpenapiParameters::Header.new(parameters) if parameters

      parameters = operation.cookie_parameters
      @cookies = OpenapiParameters::Cookie.new(parameters) if parameters
    end

    attr_reader :query, :path, :headers, :cookies

    def parse(request, route_params:)
      ParsedRequest.new(request, parsers: self, route_params:)
    end
  end
end

# frozen_string_literal: true

require_relative 'body_parser'

module OpenapiFirst
  # Lazily returns the parsed request values
  class ParsedRequest
    def initialize(request, parsers:, route_params:)
      @request = request
      @parsers = parsers
      @route_params = route_params
      @values = {}
    end

    def content_type
      request.content_type
    end

    def path_parameters
      @path_parameters ||= @parsers.path&.unpack(route_params) || {}
    end

    def query
      @query ||= @parsers.query&.unpack(request.env[Rack::QUERY_STRING]) || {}
    end

    def headers
      @headers ||= @parsers.headers&.unpack_env(request.env) || {}
    end

    def cookies
      @cookies ||= @parsers.cookies&.unpack(request.env[Rack::HTTP_COOKIE]) || {}
    end

    def body
      @body ||= BodyParser.new.parse(request, request.media_type)
    end

    private

    attr_reader :request, :parsers, :route_params
  end
end

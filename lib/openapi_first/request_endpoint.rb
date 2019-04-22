# frozen_string_literal: true

require 'rack'
require 'json_schemer'
require 'multi_json'

module OpenapiFirst
  ENDPOINT = 'openapi_first.endpoint'.freeze

  class RequestEndpoint
    def initialize(app, spec:, allow_unknown_endpoint: false)
      @app = app
      @spec = spec
      @allow_unknown_endpoint = allow_unknown_endpoint
    end

    def call(env)
      req = Rack::Request.new(env)
      env[ENDPOINT] = spec_endpoint(req)
      @app.call(env)
    rescue OasParser::PathNotFound, OasParser::MethodNotFound
      Rack::Response.new('', 404)
    end

    def spec_endpoint(req)
      @spec
        .path_by_path(req.path)
        .endpoint_by_method(req.request_method.downcase)
    end
  end
end

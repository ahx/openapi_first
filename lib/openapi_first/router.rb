# frozen_string_literal: true

require 'rack'
require 'json_schemer'
require 'multi_json'

module OpenapiFirst
  OPERATION = 'openapi_first.operation'.freeze

  class Router
    def initialize(app, spec:, allow_unknown_operation: false)
      @app = app
      @spec = spec
      @allow_unknown_operation = allow_unknown_operation
    end

    def call(env)
      req = Rack::Request.new(env)
      env[OPERATION] = spec_endpoint(req)
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

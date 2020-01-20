# frozen_string_literal: true

require 'rack'
require 'json_schemer'
require 'multi_json'
require 'mustermann/template'

module OpenapiFirst
  class Router
    NOT_FOUND = Rack::Response.new('', 404).finish.freeze

    def initialize(app, options)
      @app = app
      @spec = options.fetch(:spec)
      @allow_unknown_operation = options.fetch(:allow_unknown_operation, false)
    end

    def call(env)
      req = Rack::Request.new(env)
      operation = env[OPERATION] = @spec.find_operation(req)
      path_params = find_path_params(operation, req)
      env[PATH_PARAMS] = path_params if path_params
      return @app.call(env) if operation || @allow_unknown_operation

      NOT_FOUND
    end

    def find_path_params(operation, req)
      return unless operation&.path_parameters&.any?

      pattern = Mustermann::Template.new(operation.path.path)
      pattern.params(req.path)
    end
  end
end

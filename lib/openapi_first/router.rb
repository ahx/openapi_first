# frozen_string_literal: true

require 'rack'
require 'multi_json'
require 'mustermann'
require_relative 'body_parser'

module OpenapiFirst
  class Router
    # The unconverted path parameters before they are converted to the types defined in the API description
    RAW_PATH_PARAMS = 'openapi.raw_path_params'

    NOT_FOUND = Rack::Response.new('Not Found', 404).finish.freeze
    METHOD_NOT_ALLOWED = Rack::Response.new('Method Not Allowed', 405).finish.freeze

    def initialize(
      app,
      options
    )
      @app = app
      @raise = options.fetch(:raise_error, false)
      @not_found = options.fetch(:not_found, :halt)
      @error_response_class = options.fetch(:error_response, OpenapiFirst.configuration.error_response)
      spec = options.fetch(:spec)
      raise "You have to pass spec: when initializing #{self.class}" unless spec

      @definition = spec.is_a?(Definition) ? spec : OpenapiFirst.load(spec)
      @filepath = @definition.filepath
    end

    def call(env)
      env[OPERATION] = nil
      request = Rack::Request.new(env)
      path_item, path_params = @definition.find_path_item_and_params(request.path)
      operation = path_item&.find_operation(request.request_method.downcase)

      env[OPERATION] = operation
      env[RAW_PATH_PARAMS] = path_params

      if operation.nil?
        raise_error(env) if @raise
        return @app.call(env) if @not_found == :continue
      end

      return NOT_FOUND unless path_item
      return METHOD_NOT_ALLOWED unless operation

      @app.call(env)
    end

    ORIGINAL_PATH = 'openapi_first.path_info'
    private_constant :ORIGINAL_PATH

    ROUTER_PARSED_BODY = 'router.parsed_body'
    private_constant :ROUTER_PARSED_BODY

    private

    def raise_error(env)
      req = Rack::Request.new(env)
      msg =
        "Could not find definition for #{req.request_method} '#{
          req.path
        }' in API description #{@filepath}"
      raise NotFoundError, msg
    end
  end
end

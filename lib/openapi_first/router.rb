# frozen_string_literal: true

require 'rack'
require 'multi_json'
require 'hanami/router'
require_relative 'body_parser_middleware'

module OpenapiFirst
  class Router
    def initialize(
      app,
      options
    )
      @app = app
      @parent_app = options.fetch(:parent_app, nil)
      @raise = options.fetch(:raise_error, false)
      @not_found = options.fetch(:not_found, :halt)
      spec = options.fetch(:spec)
      raise "You have to pass spec: when initializing #{self.class}" unless spec

      spec = OpenapiFirst.load(spec) unless spec.is_a?(Definition)

      @filepath = spec.filepath
      @router = build_router(spec.operations)
    end

    def call(env)
      env[OPERATION] = nil
      response = call_router(env)
      if env[OPERATION].nil?
        return @parent_app.call(env) if @parent_app # This should only happen if used via OpenapiFirst.middleware

        raise_error(env) if @raise

        return @app.call(env) if @not_found == :continue
      end

      response
    end

    ORIGINAL_PATH = 'openapi_first.path_info'

    private

    def raise_error(env)
      req = Rack::Request.new(env)
      msg =
        "Could not find definition for #{req.request_method} '#{
          req.path
        }' in API description #{@filepath}"
      raise NotFoundError, msg
    end

    def call_router(env)
      # Changing and restoring PATH_INFO is needed, because Hanami::Router does not respect existing script_path
      env[ORIGINAL_PATH] = env[Rack::PATH_INFO]
      env[Rack::PATH_INFO] = Rack::Request.new(env).path
      @router.call(env)
    rescue BodyParsingError => e
      handle_body_parsing_error(e)
    ensure
      env[Rack::PATH_INFO] = env.delete(ORIGINAL_PATH) if env[ORIGINAL_PATH]
    end

    def handle_body_parsing_error(exception)
      err = { title: 'Failed to parse body as application/json', status: '400' }
      err[:detail] = exception.cause unless ENV['RACK_ENV'] == 'production'
      errors = [err]
      raise RequestInvalidError, errors if @raise

      Rack::Response.new(
        MultiJson.dump(errors: errors),
        400,
        Rack::CONTENT_TYPE => 'application/vnd.api+json'
      ).finish
    end

    def build_router(operations)
      router = Hanami::Router.new.tap do |r|
        operations.each do |operation|
          normalized_path = operation.path.gsub('{', ':').gsub('}', '')
          r.public_send(
            operation.method,
            normalized_path,
            to: build_route(operation)
          )
        end
      end
      raise_error = @raise
      Rack::Builder.app do
        use BodyParserMiddleware, raise_error: raise_error
        run router
      end
    end

    def build_route(operation)
      lambda do |env|
        env[OPERATION] = operation
        path_info = env.delete(ORIGINAL_PATH)
        route_params = Utils::StringKeyedHash.new(env['router.params'])
        env[PARAMETERS] = OpenapiParameters::Path.new(operation.path_parameters).unpack(route_params)
        env[Rack::PATH_INFO] = path_info
        @app.call(env)
      end
    end
  end
end

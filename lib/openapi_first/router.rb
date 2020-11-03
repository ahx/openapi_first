# frozen_string_literal: true

require 'rack'
require 'hanami/router'
require_relative 'utils'

module OpenapiFirst
  class Router
    def initialize(
      app,
      spec:,
      raise_error: false,
      not_found: :halt,
      parent_app: nil
    )
      @app = app
      @parent_app = parent_app
      @raise = raise_error
      @not_found = not_found
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
      msg = "Could not find definition for #{req.request_method.upcase} '#{req.path}' in API description #{@filepath}"
      raise NotFoundError, msg
    end

    def call_router(env)
      # Changing and restoring PATH_INFO is needed, because Hanami::Router does not respect existing script_path
      env[ORIGINAL_PATH] = env[Rack::PATH_INFO]
      env[Rack::PATH_INFO] = Rack::Request.new(env).path
      @router.call(env)
    ensure
      env[Rack::PATH_INFO] = env.delete(ORIGINAL_PATH) if env[ORIGINAL_PATH]
    end

    def build_router(operations) # rubocop:disable Metrics/AbcSize
      router = Hanami::Router.new {}
      operations.each do |operation|
        normalized_path = operation.path.gsub('{', ':').gsub('}', '')
        if operation.operation_id.nil?
          warn "operationId is missing in '#{operation.request_method} #{operation.path}'. I am ignoring this operation." # rubocop:disable Layout/LineLength
        end
        router.public_send(
          operation.request_method.downcase,
          normalized_path,
          to: lambda do |env|
            env[OPERATION] = operation
            env[PARAMETERS] = env['router.params']
            env[Rack::PATH_INFO] = env.delete(ORIGINAL_PATH)
            @app.call(env)
          end
        )
      end
      router
    end
  end
end

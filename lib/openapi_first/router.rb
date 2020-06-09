# frozen_string_literal: true

require 'rack'
require 'hanami/router'
require_relative 'utils'

module OpenapiFirst
  class Router
    NOT_FOUND = Rack::Response.new('', 404).finish.freeze
    DEFAULT_NOT_FOUND_APP = ->(_env) { NOT_FOUND }

    def initialize(
      app,
      spec:,
      raise_error: false,
      parent_app: nil,
      not_found: nil
    )
      @app = app
      @parent_app = parent_app
      @raise = raise_error
      @failure_app = find_failure_app(not_found)
      if @failure_app.nil?
        raise ArgumentError,
              'not_found must be nil, :continue or must respond to call'
      end
      @filepath = spec.filepath
      @router = build_router(spec.operations)
    end

    def call(env)
      env[OPERATION] = nil
      route = find_route(env)
      return route.call(env) if route.routable?

      return @parent_app.call(env) if @parent_app # This should only happen if used via OpenapiFirst.middlware

      if @raise
        req = Rack::Request.new(env)
        msg = "Could not find definition for #{req.request_method} '#{req.path}' in API description #{@filepath}"
        raise NotFoundError, msg
      end

      @failure_app.call(env)
    end

    private

    def find_failure_app(option)
      return DEFAULT_NOT_FOUND_APP if option.nil?
      return @app if option == :continue

      option if option.respond_to?(:call)
    end

    def find_route(env)
      original_path_info = env[Rack::PATH_INFO]
      env[Rack::PATH_INFO] = Rack::Request.new(env).path
      @router.recognize(env)
    ensure
      env[Rack::PATH_INFO] = original_path_info
    end

    def build_router(operations) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      router = Hanami::Router.new {}
      operations.each do |operation|
        normalized_path = operation.path.gsub('{', ':').gsub('}', '')
        if operation.operation_id.nil?
          warn "operationId is missing in '#{operation.method} #{operation.path}'. I am ignoring this operation."
          next
        end
        router.public_send(
          operation.method,
          normalized_path,
          to: lambda do |env|
            env[OPERATION] = operation
            env[PARAMETERS] = Utils.deep_stringify(env['router.params'])
            @app.call(env)
          end
        )
      end
      router
    end
  end
end

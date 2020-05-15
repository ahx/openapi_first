# frozen_string_literal: true

require 'rack'
require 'hanami/router'
require_relative 'utils'

module OpenapiFirst
  class Router
    NOT_FOUND = Rack::Response.new('', 404).finish.freeze

    def initialize(app, options)
      @app = app
      @parent_app = options.fetch(:parent_app, nil)
      @router = build_router(options.fetch(:spec).operations)
    end

    def call(env)
      endpoint = find_endpoint(env)
      return endpoint.call(env) if endpoint
      return @parent_app.call(env) if @parent_app

      NOT_FOUND
    end

    private

    def find_endpoint(env)
      original_path_info = env[Rack::PATH_INFO]
      # Overwrite PATH_INFO temporarily, because hanami-router does not respect SCRIPT_NAME # rubocop:disable Layout/LineLength
      env[Rack::PATH_INFO] = Rack::Request.new(env).path
      @router.recognize(env).endpoint
    ensure
      env[Rack::PATH_INFO] = original_path_info
    end

    def build_router(operations) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      router = Hanami::Router.new {}
      operations.each do |operation|
        normalized_path = operation.path.gsub('{', ':').gsub('}', '')
        if operation.operation_id.nil?
          warn "operationId is missing in '#{operation.method} #{operation.path}'. I am ignoring this operation." # rubocop:disable Layout/LineLength
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

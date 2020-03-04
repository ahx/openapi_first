# frozen_string_literal: true

require 'rack'
require 'hanami/router'

module OpenapiFirst
  class Router
    NOT_FOUND = Rack::Response.new('', 404).finish.freeze

    def initialize(app, options)
      @app = app
      @allow_unknown_operation = options.fetch(:allow_unknown_operation, false)
      @router = build_router(options.fetch(:spec).operations)
    end

    def call(env)
      route = @router.recognize(env)
      operation = env[OPERATION] = route.endpoint
      env[PATH_PARAMS] = route.params
      return @app.call(env) if operation || @allow_unknown_operation

      NOT_FOUND
    end

    private

    def build_router(operations)
      router = Hanami::Router.new { }
      operations.each do |operation|
        normalized_path = operation.path.path.gsub('{', ':').gsub('}', '')
        # TODO: Fail loudly if operationIs is missing
        next if operation.operation_id.nil?

        router.public_send(
          operation.method,
          normalized_path,
          to: operation
        )
      end
      router
    end
  end
end

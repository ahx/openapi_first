# frozen_string_literal: true

require 'rack'
require 'hanami/router'

module OpenapiFirst
  class Router
    NOT_FOUND = Rack::Response.new('', 404).finish.freeze

    def initialize(app, options)
      @app = app
      @namespace = options.fetch(:namespace)
      @router = build_router(options.fetch(:spec).operations)
    end

    def call(env)
      @router.call(env)
    end

    private

    def build_router(operations)
      router = Hanami::Router.new {}
      operations.each do |operation|
        normalized_path = operation.path.path.gsub('{', ':').gsub('}', '')
        # TODO: Fail loudly if operationId is missing
        next if operation.operation_id.nil?

        router.public_send(
          operation.method,
          normalized_path,
          to: lambda do |env|
            env[OPERATION] = operation
            env[PATH_PARAMS] = env['router.params']
            env[HANDLER] = find_handler(operation.operation_id)
            @app.call(env)
          end
        )
      end
      router
    end

    def find_handler(operation_id)
      if operation_id.include?('.')
        module_name, method_name = operation_id.split('.')
        return @namespace.const_get(module_name.camelize).method(method_name)
      end

      if operation_id.include?('#')
        module_name, class_name = operation_id.split('#')
        klass = @namespace.const_get(module_name.camelize)
                          .const_get(class_name.camelize)
        return ->(params, res) { klass.new(params, res) }
      end
      @namespace.method(operation_id)
    end
  end
end

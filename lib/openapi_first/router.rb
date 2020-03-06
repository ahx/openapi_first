# frozen_string_literal: true

require 'rack'
require 'hanami/router'
require 'hanami/utils/string'

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

    def find_handler(operation_id)
      name = Hanami::Utils::String.underscore(operation_id)
      if name.include?('.')
        module_name, method_name = name.split('.')
        return @namespace.const_get(module_name.camelize).method(method_name)
      end

      if name.include?('#')
        module_name, class_name = name.split('#')
        klass = @namespace.const_get(module_name.camelize)
                          .const_get(class_name.camelize)
        return ->(params, res) { klass.new.call(params, res) }
      end
      @namespace.method(name)
    end

    private

    def build_router(operations)
      router = Hanami::Router.new {}
      operations.each do |operation|
        normalized_path = operation.path.path.gsub('{', ':').gsub('}', '')
        if operation.operation_id.nil?
          warn "operationId is missing in '#{operation.method} #{operation.path.path}'. I am ignoring this operation."
        end

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
  end
end

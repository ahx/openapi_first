# frozen_string_literal: true

require 'rack'
require 'hanami/router'
require_relative 'utils'

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
      name = operation_id.match(/:*(.*)/)&.to_a[1]
      return if name.nil?

      if name.include?('.')
        module_name, method_name = name.split('.')
        klass = find_const(@namespace, module_name)
        return klass&.method(Utils.underscore(method_name))
      end
      if name.include?('#')
        module_name, klass_name = name.split('#')
        const = find_const(@namespace, module_name)
        klass = find_const(const, klass_name)
        return ->(params, res) { klass.new.call(params, res) }
      end
      @namespace.method(Utils.underscore(name))
    end

    private

    def find_const(parent, name)
      name = Utils.classify(name)
      return unless parent.const_defined?(name, false)

      parent.const_get(name, false)
    end

    def build_router(operations)
      router = Hanami::Router.new {}
      operations.each do |operation|
        normalized_path = operation.path.path.gsub('{', ':').gsub('}', '')
        if operation.operation_id.nil?
          warn "operationId is missing in '#{operation.method} #{operation.path.path}'. I am ignoring this operation."
          next
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

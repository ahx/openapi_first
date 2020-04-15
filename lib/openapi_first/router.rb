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
      @parent_app = options.fetch(:parent_app, nil)
      @router = build_router(options.fetch(:spec).operations)
    end

    def call(env)
      route = @router.recognize(env)
      return route.endpoint.call(env) if route.routable?

      return @parent_app.call(env) if @parent_app

      NOT_FOUND
    end

    def find_handler(operation_id) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      name = operation_id.match(/:*(.*)/)&.to_a&.at(1)
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
        if klass.instance_method(:initialize).arity.zero?
          return ->(params, res) { klass.new.call(params, res) }
        end

        return ->(params, res) { klass.new(params.env).call(params, res) }
      end
      method_name = Utils.underscore(name)
      return unless @namespace.respond_to?(method_name)

      @namespace.method(method_name)
    end

    private

    def find_const(parent, name)
      name = Utils.classify(name)
      return unless parent.const_defined?(name, false)

      parent.const_get(name, false)
    end

    def build_router(operations) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      router = Hanami::Router.new {}
      operations.each do |operation|
        normalized_path = operation.path.gsub('{', ':').gsub('}', '')
        if operation.operation_id.nil?
          warn "operationId is missing in '#{operation.method} #{operation.path}'. I am ignoring this operation." # rubocop:disable Layout/LineLength
          next
        end
        handler = find_handler(operation.operation_id)
        if handler.nil?
          warn "could not find handler for '#{operation.operation_id}' (#{operation.method} #{operation.path}). I am ignoring this operation." # rubocop:disable Layout/LineLength
          next
        end
        router.public_send(
          operation.method,
          normalized_path,
          to: lambda do |env|
            env[OPERATION] = operation
            env[PARAMS] = Utils.deep_stringify(env['router.params'])
            env[HANDLER] = handler
            @app.call(env)
          end
        )
      end
      router
    end
  end
end

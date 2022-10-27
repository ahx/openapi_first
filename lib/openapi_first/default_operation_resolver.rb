# frozen_string_literal: true

require_relative 'utils'

module OpenapiFirst
  class DefaultOperationResolver
    def initialize(namespace)
      @namespace = namespace
      @handlers = {}
    end

    def call(operation)
      @handlers[operation.name] ||= begin
        id = handler_id(operation)
        find_handler(id) if id
      end
    end

    def find_handler(id)
      name = id.match(/:*(.*)/)&.to_a&.at(1)
      return if name.nil?

      catch :halt do
        return find_class_method_handler(name) if name.include?('.')
        return find_instance_method_handler(name) if name.include?('#')
      end
      method_name = Utils.underscore(name)
      return unless @namespace.respond_to?(method_name)

      @namespace.method(method_name)
    end

    def handler_id(operation)
      id = operation['x-handler'] || operation['operationId']
      if id.nil?
        raise HandlerNotFoundError,
              "operationId or x-handler is missing in '#{operation.method} #{operation.path}' so I cannot find a handler for this operation." # rubocop:disable Layout/LineLength
      end

      id
    end

    def find_class_method_handler(name)
      module_name, method_name = name.split('.')
      klass = find_const(@namespace, module_name)
      klass.method(Utils.underscore(method_name))
    end

    def find_instance_method_handler(name)
      module_name, klass_name = name.split('#')
      const = find_const(@namespace, module_name)
      klass = find_const(const, klass_name)
      klass.new
    end

    def find_const(parent, name)
      name = Utils.classify(name)
      throw :halt unless parent.const_defined?(name, false)

      parent.const_get(name, false)
    end
  end
end

# frozen_string_literal: true

require_relative 'utils'

module OpenapiFirst
  class FindHandler
    def initialize(spec, namespace)
      @spec = spec
      @namespace = namespace
    end

    def all
      @spec.operations.each_with_object({}) do |operation, hash|
        operation_id = operation.operation_id
        handler = self[operation_id]
        if handler.nil?
          warn "#{self.class.name} cannot not find handler for '#{operation.operation_id}' (#{operation.method} #{operation.path}). This operation will be ignored." # rubocop:disable Layout/LineLength
          next
        end
        hash[operation_id] = handler
      end
    end

    def [](operation_id) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
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
        return ->(params, res) { klass.new.call(params, res) } if klass.instance_method(:initialize).arity.zero?

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
  end
end

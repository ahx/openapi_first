# frozen_string_literal: true

module OpenapiFirst
  # Plugin system for extending openapi_first behaviour. Modeled after Sequels plugin system.
  #
  # A plugin is a module under the +OpenapiFirst::Plugins+ namespace with a
  # +.configure(config, **opts)+ class method. Plugins wire themselves in by
  # registering hooks on the +Configuration+ object they receive.
  #
  # Loading a plugin:
  #
  #   # Globally (applies to all definitions):
  #   OpenapiFirst.plugin :x_public
  #
  #   # Per definition:
  #   OpenapiFirst.load('openapi.yaml') { |c| c.plugin :x_public, field: 'x-visible' }
  #
  # Writing a plugin:
  #
  #   module OpenapiFirst::Plugins::MyPlugin
  #     def self.configure(config, **)
  #       config.after_request_validation do |validated_request|
  #         # ...
  #       end
  #     end
  #   end
  #
  # Third-party plugins are discovered by placing a module at the expected
  # constant path and/or providing a file at <tt>openapi_first/plugins/<name></tt>
  # on the load path.
  module Plugins
    def self.load(name)
      module_name = name.to_s.split('_').map(&:capitalize).join
      mod = const_get(module_name) if const_defined?(module_name, false)
      mod ||= begin
        require "openapi_first/plugins/#{name}"
        const_get(module_name)
      end
      raise ArgumentError, "Plugin #{name.inspect} must respond to .configure" unless mod.respond_to?(:configure)

      mod
    end
  end
end

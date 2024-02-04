# frozen_string_literal: true

module OpenapiFirst
  # Plugin System adapted from
  # Polished Ruby Programming by Jeremy Evans
  # https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewBook?id=0
  # @!visibility private
  module Plugins
    PLUGINS = {} # rubocop:disable Style/MutableConstant
    private_constant :PLUGINS

    def register(name, klass)
      PLUGINS[name.to_sym] = klass
    end

    def plugin(name)
      require "openapi_first/plugins/#{name}"
      PLUGINS.fetch(name.to_sym)
    end

    def find_plugin(name)
      PLUGINS.fetch(name)
    end
  end
end

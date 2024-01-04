# frozen_string_literal: true

module OpenapiFirst
  # Plugin System adapted from
  # Polished Ruby Programming by Jeremy Evans
  # https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewBook?id=0
  module Plugins
    PLUGINS = {} # rubocop:disable Style/MutableConstant

    def register(name, klass)
      PLUGINS[name] = klass
    end

    def plugin(name)
      require "openapi_first/plugins/#{name}"
      PLUGINS.fetch(name)
    end
  end
end

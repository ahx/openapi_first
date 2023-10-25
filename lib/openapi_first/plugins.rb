# frozen_string_literal: true

module OpenapiFirst
  module Plugins
    ERROR_RESPONSES = {} # rubocop:disable Style/MutableConstant

    def self.register_error_response(name, klass)
      ERROR_RESPONSES[name] = klass
    end

    def self.find_error_response(name)
      return name if name.is_a?(Class)

      ERROR_RESPONSES.fetch(name)
    end
  end
end

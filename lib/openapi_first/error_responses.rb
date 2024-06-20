# frozen_string_literal: true

module OpenapiFirst
  # Error responses for request validation.
  module ErrorResponses
    REGISTRY = {} # rubocop:disable Style/MutableConstant
    private_constant :REGISTRY

    def self.register(name, klass)
      REGISTRY[name.to_sym] = klass
    end

    def self.find(name)
      REGISTRY.fetch(name)
    end
  end
end

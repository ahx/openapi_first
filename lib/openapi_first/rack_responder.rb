# frozen_string_literal: true

require 'rack'
require 'multi_json'
require_relative 'inbox'
require_relative 'default_operation_resolver'

module OpenapiFirst
  class RackResponder
    def initialize(namespace: nil, resolver: nil)
      @resolver = resolver || DefaultOperationResolver.new(namespace)
      @namespace = namespace
    end

    def call(env)
      operation = env[OpenapiFirst::OPERATION]
      find_handler(operation)&.call(env)
    end

    private

    def find_handler(operation)
      handler = @resolver.call(operation)
      raise NotImplementedError, "Could not find handler for #{operation.name}" unless handler

      handler
    end

    def serialize(result)
      return result if result.is_a?(String)

      MultiJson.dump(result)
    end
  end
end

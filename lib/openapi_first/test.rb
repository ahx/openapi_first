# frozen_string_literal: true

require_relative 'test/methods'

module OpenapiFirst
  # Test integration
  module Test
    def self.register(path, as: :default)
      @registry ||= {}
      @registry[as] = OpenapiFirst.load(path)
    end

    def self.[](api)
      @registry[api] || raise(ArgumentError,
                              "API description #{api} not found to be used via assert_api_conform. " \
                              'Use OpenapiFirst::Test.register to load an API description first.')
    end
  end
end

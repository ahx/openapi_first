# frozen_string_literal: true

require_relative 'test/methods'

module OpenapiFirst
  # Test integration
  module Test
    class NotRegisteredError < StandardError; end

    DEFINITIONS = {} # rubocop:disable Style/MutableConstant
  
    def self.definitions = DEFINITIONS

    def self.register(path, as: :default)
      definitions[as] = OpenapiFirst.load(path)
    end

    def self.[](api)
      definitions.fetch(api) do
        option = api == :default ? '' : ", as: #{api.inspect}"
        raise(NotRegisteredError,
              "API description '#{api.inspect}' not found." \
              "Please call OpenapiFirst::Test.register('myopenapi.yaml'#{option}) " \
              'once before calling assert_api_conform.')
      end
    end
  end
end

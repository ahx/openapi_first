# frozen_string_literal: true

require_relative 'test/methods'

module OpenapiFirst
  # Test integration
  module Test
    autoload :Coverage, 'openapi_first/test/coverage'

    def self.minitest?(base)
      base.include?(::Minitest::Assertions)
    rescue NameError
      false
    end

    # Returns the Rack app wrapped with silent request, response validation
    # You can use this if you want to track coverage via Test::Coverage, but don't want to use
    # the middlewares or manual request, response validation.
    def self.app(app, spec:)
      Rack::Builder.app do
        use OpenapiFirst::Middlewares::ResponseValidation, spec:, raise_error: false
        use OpenapiFirst::Middlewares::RequestValidation, spec:, raise_error: false, error_response: false
        run app
      end
    end

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

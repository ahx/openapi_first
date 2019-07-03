# frozen_string_literal: true

require 'rack'

module OpenapiFirst
  # Use .app when using Rack's `run` instead of `App.new`.
  # This will allow us to run a "compile" step before generating the app.
  def self.app(spec, namespace:)
    spec = OpenapiFirst.load(spec) if spec.is_a?(String)
    App.new(spec, namespace: namespace)
  end

  # Use .middleware when using Rack's `use` instead of `App, options`.
  # This will allow us to run a "compile" step before generating the app.
  def self.middleware(spec, namespace:)
    spec = OpenapiFirst.load(spec) if spec.is_a?(String)
    AppWithOptions.new(spec, namespace: namespace)
  end

  class AppWithOptions
    def initialize(*options)
      @options = options
    end

    def new(app)
      App.new(app, *@options)
    end
  end

  class App
    def initialize(
      app = nil, # rubocop:disable Style/OptionalArguments
      spec,
      namespace:,
      allow_unknown_operation: !app.nil?
    )
      @stack = Rack::Builder.new do
        use OpenapiFirst::Router,
            spec: spec,
            allow_unknown_operation: allow_unknown_operation
        use OpenapiFirst::QueryParameterValidation
        use OpenapiFirst::RequestBodyValidation
        run OpenapiFirst::OperationResolver.new(app, namespace: namespace)
      end
    end

    def call(env)
      @stack.call(env)
    end
  end
end

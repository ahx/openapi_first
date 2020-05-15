# frozen_string_literal: true

require 'rack'
require 'logger'

module OpenapiFirst
  class App
    def initialize(
      parent_app,
      spec,
      namespace:
    )
      @stack = Rack::Builder.app do
        freeze_app
        use OpenapiFirst::Router, spec: spec, parent_app: parent_app
        use OpenapiFirst::RequestValidation
        run OpenapiFirst::OperationResolver.new(
          spec: spec,
          namespace: namespace
        )
      end
    end

    def call(env)
      @stack.call(env)
    end
  end
end

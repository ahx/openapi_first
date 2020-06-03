# frozen_string_literal: true

require 'rack'
require 'logger'

module OpenapiFirst
  class App
    def initialize(parent_app, spec, namespace:, router_raise:)
      @stack = Rack::Builder.app do
        freeze_app
        use OpenapiFirst::Router, spec: spec, raise: router_raise, parent_app: parent_app
        use OpenapiFirst::RequestValidation
        run OpenapiFirst::Responder.new(
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

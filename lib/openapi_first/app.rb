# frozen_string_literal: true

require 'rack'
require 'logger'

module OpenapiFirst
  class App
    def initialize( # rubocop:disable Metrics/ParameterLists
      parent_app,
      spec,
      namespace:,
      router_raise_error: false,
      request_validation_raise_error: false,
      response_validation: false,
      resolver: nil
    )
      @stack = Rack::Builder.app do
        freeze_app
        use OpenapiFirst::Router, spec: spec, raise_error: router_raise_error, parent_app: parent_app
        use OpenapiFirst::RequestValidation, raise_error: request_validation_raise_error
        use OpenapiFirst::ResponseValidation if response_validation
        run OpenapiFirst::Responder.new(namespace: namespace, resolver: resolver)
      end
    end

    def call(env)
      @stack.call(env)
    end
  end
end

# frozen_string_literal: true

require 'rack'

module OpenapiFirst
  class App
    def initialize(
      app = nil,
      spec, namespace:,
      allow_unknown_operation: !app.nil?
    )
      spec = OpenapiFirst.load(spec) if spec.is_a?(String)
      @stack = Rack::Builder.new do
        use OpenapiFirst::Router, spec: spec, allow_unknown_operation: allow_unknown_operation
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

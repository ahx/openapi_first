# frozen_string_literal: true

module OpenapiFirst
  class Coverage
    attr_reader :to_be_called

    def initialize(app, spec)
      @app = app
      @spec = spec
      @to_be_called = spec.operations.map do |operation|
        endpoint_id(operation)
      end
    end

    def call(env)
      response = @app.call(env)
      operation = env[OPERATION]
      @to_be_called.delete(endpoint_id(operation)) if operation
      response
    end

    private

    def endpoint_id(operation)
      "#{operation.path}##{operation.method}"
    end
  end
end

# frozen_string_literal: true

require 'rack'

module OpenapiFirst
  class OperationResolver
    def initialize(app, namespace:)
      @app = app
      @namespace = namespace
    end

    def call(env)
      endpoint = env[OpenapiFirst::OPERATION]
      return @app.call(env) unless endpoint

      operation_id = endpoint.operation_id
      res = Rack::Response.new
      result = call_operation_method(operation_id, env, res)
      res.write MultiJson.dump(result) if result && res.body.empty?
      res
    end

    def call_operation_method(operation_id, env, res)
      target = @namespace
      methods = operation_id.split('.')
      final = methods.pop
      methods.each { |m| target = target.send(m) }
      params = build_params(env)
      target.send(final, params, res)
    end

    def build_params(env)
      sources = [env[QUERY_PARAMS], env[REQUEST_BODY]].tap(&:compact!)
      hash = {}.merge!(*sources)
      hash.define_singleton_method(:env) { env }
      hash
    end
  end
end

# frozen_string_literal: true

require 'rack'

module OpenapiFirst
  class OperationResolver
    DEFAULT_APP = ->(_env) { Rack::Response.new('', 404) }

    def initialize(app = DEFAULT_APP, namespace:)
      @app = app
      @namespace = namespace
    end

    def call(env)
      operation = env[OpenapiFirst::OPERATION]
      return @app.call(env) unless operation

      operation_id = operation.operation_id
      res = Rack::Response.new
      result = call_operation_method(operation_id, env, res)
      res.write MultiJson.dump(result) if result && res.body.empty?
      res[Rack::CONTENT_TYPE] ||= find_content_type(operation, res.status)
      res.finish
    end

    private

    def find_content_type(operation, status)
      content = operation
                .response_by_code(status.to_s, use_default: true)
                .content
      content.keys[0] if content
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
      sources = [
        env[PATH_PARAMS],
        env[QUERY_PARAMS],
        env[REQUEST_BODY]
      ].tap(&:compact!)
      hash = {}.merge!(*sources)
      hash.define_singleton_method(:env) { env }
      hash
    end
  end
end

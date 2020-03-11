# frozen_string_literal: true

require 'rack'

module OpenapiFirst
  class OperationResolver
    def call(env)
      operation = env[OpenapiFirst::OPERATION]
      res = Rack::Response.new
      params = build_params(env)
      handler = env[HANDLER]
      result = handler.call(params, res)
      res.write serialize(result) if result && res.body.empty?
      res[Rack::CONTENT_TYPE] ||= operation.content_type_for(res.status)
      res.finish
    end

    private

    def serialize(result)
      return result if result.is_a?(String)

      MultiJson.dump(result)
    end

    def build_params(env)
      sources = [
        env[PARAMS],
        env[REQUEST_BODY]
      ].tap(&:compact!)
      Params.new(env).merge!(*sources)
    end
  end

  class Params < Hash
    attr_reader :env

    def initialize(env)
      @env = env
      super
    end
  end
end

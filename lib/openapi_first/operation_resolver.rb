# frozen_string_literal: true

require 'rack'

module OpenapiFirst
  class OperationResolver
    def call(env) # rubocop:disable Metrics/AbcSize
      operation = env[OpenapiFirst::OPERATION]
      return @app.call(env) unless operation

      operation_id = operation.operation_id
      res = Rack::Response.new
      params = build_params(env)
      handler = env[HANDLER]
      result = handler.call(params, res)
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

    def build_params(env)
      sources = [
        env[PATH_PARAMS],
        env[QUERY_PARAMS],
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

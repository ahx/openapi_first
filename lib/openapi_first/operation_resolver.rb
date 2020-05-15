# frozen_string_literal: true

require 'rack'
require_relative 'inbox'
require_relative 'find_handler'

module OpenapiFirst
  class OperationResolver
    def initialize(spec:, namespace:)
      @handlers = FindHandler.new(spec, namespace).all
      @namespace = namespace
    end

    def call(env)
      operation = env[OpenapiFirst::OPERATION]
      res = Rack::Response.new
      handler = @handlers[operation.operation_id]
      result = handler.call(env[INBOX], res)
      res.write serialize(result) if result && res.body.empty?
      res[Rack::CONTENT_TYPE] ||= operation.content_type_for(res.status)
      res.finish
    end

    private

    def serialize(result)
      return result if result.is_a?(String)

      MultiJson.dump(result)
    end
  end
end

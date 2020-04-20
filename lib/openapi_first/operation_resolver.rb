# frozen_string_literal: true

require 'rack'
require_relative 'inbox'

module OpenapiFirst
  class OperationResolver
    def call(env)
      operation = env[OpenapiFirst::OPERATION]
      res = Rack::Response.new
      inbox = env[INBOX] = build_inbox(env)
      handler = env[HANDLER]
      result = handler.call(inbox, res)
      res.write serialize(result) if result && res.body.empty?
      res[Rack::CONTENT_TYPE] ||= operation.content_type_for(res.status)
      res.finish
    end

    private

    def serialize(result)
      return result if result.is_a?(String)

      MultiJson.dump(result)
    end

    def build_inbox(env)
      sources = [
        env[PARAMETERS],
        env[REQUEST_BODY]
      ].tap(&:compact!)
      Inbox.new(env).merge!(*sources)
    end
  end
end

# frozen_string_literal: true

require 'rack'
require 'multi_json'
require_relative 'inbox'
require_relative 'responder'
require_relative 'default_operation_resolver'

module OpenapiFirst
  class RackResponder < Responder
    def call(env)
      operation = env[OpenapiFirst::OPERATION]
      find_handler(operation)&.call(env)
    end
  end
end

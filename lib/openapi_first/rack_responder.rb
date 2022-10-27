# frozen_string_literal: true

require_relative 'responder'

module OpenapiFirst
  class RackResponder < Responder
    def call(env)
      operation = env[OpenapiFirst::OPERATION]
      find_handler(operation)&.call(env)
    end
  end
end

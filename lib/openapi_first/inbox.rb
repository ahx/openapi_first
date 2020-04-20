# frozen_string_literal: true

module OpenapiFirst
  # An instance of this gets passed to handler functions as first argument.
  class Inbox < Hash
    attr_reader :env

    def initialize(env)
      @env = env
      super()
    end
  end
end

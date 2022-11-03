# frozen_string_literal: true

module OpenapiFirst
  module UseRouter
    def initialize(app, options = {})
      @app = app
      @options = options
      super
    end

    def call(env)
      return super if env.key?(OPERATION)

      @router ||= Router.new(->(e) { super(e) }, @options)
      @router.call(env)
    end
  end
end

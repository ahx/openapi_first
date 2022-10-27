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

      @router ||= Router.new(lambda { |e|
                               super(e)
                             }, spec: @options.fetch(:spec), raise_error: @options.fetch(:raise_error, false))
      @router.call(env)
    end
  end
end

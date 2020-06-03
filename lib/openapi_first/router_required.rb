# frozen_string_literal: true

module OpenapiFirst
  module RouterRequired
    def call(env)
      unless env.key?(OPERATION)
        raise 'OpenapiFirst::Router missing in middleware stack. Did you forget adding OpenapiFirst::Router?'
      end

      super
    end
  end
end

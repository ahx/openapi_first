# frozen_string_literal: true

require_relative 'minitest_helpers'
require_relative 'plain_helpers'

module OpenapiFirst
  module Test
    # Methods to use in integration tests
    module Methods
      def self.[](application_under_test = nil, api: :default)
        mod = Module.new do
          def self.included(base)
            OpenapiFirst::Test::Methods.included(base)
          end
        end
        mod.define_method(:app) { OpenapiFirst::Test.app(application_under_test, api:) } if application_under_test
        mod
      end

      def self.included(base)
        if Test.minitest?(base)
          base.include(OpenapiFirst::Test::MinitestHelpers)
        else
          base.include(OpenapiFirst::Test::PlainHelpers)
        end
      end
    end
  end
end

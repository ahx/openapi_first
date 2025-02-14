# frozen_string_literal: true

require_relative 'minitest_helpers'
require_relative 'plain_helpers'

module OpenapiFirst
  module Test
    # Methods to use in integration tests
    module Methods
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

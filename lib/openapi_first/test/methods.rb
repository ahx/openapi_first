# frozen_string_literal: true

require_relative 'minitest_helpers'
require_relative 'plain_helpers'

module OpenapiFirst
  module Test
    # Methods to use in integration tests
    module Methods
      # @api private
      def self.included(base)
        base.include(DefaultApiMethod)
        base.include(AssertionMethod)
      end

      # Returns a module to include into a test class. It adds `assert_api_conform` and, if you
      # pass an app, an `app` method for rack-test that validates silently and tracks coverage.
      # @example
      #   RSpec.configure do |config|
      #     config.include OpenapiFirst::Test::Methods[MyApp, api: :v1], type: :request
      #   end
      # @param application_under_test [#call, nil] The Rack app to define `app` for
      # @param api [Symbol, nil] The registered API description to use. Defaults to the `:api` metadata
      #   of the RSpec example group, else :default.
      # @param validate_request_before_handling [Boolean] Validate the request before the app handles it
      #   instead of after
      # @return [Module]
      def self.[](application_under_test = nil, api: nil, validate_request_before_handling: false)
        mod = Module.new do
          def self.included(base)
            base.include OpenapiFirst::Test::Methods::AssertionMethod
          end
        end
        mod.define_method(:openapi_first_validate_request_before_handling?) { validate_request_before_handling }

        if api
          mod.define_method(:openapi_first_default_api) { api }
        else
          mod.include(DefaultApiMethod)
        end

        if application_under_test
          mod.define_method(:app) do
            OpenapiFirst::Test.app(
              application_under_test, api: openapi_first_default_api,
                                      validate_request_before_handling: openapi_first_validate_request_before_handling?
            )
          end
        end

        mod
      end

      # Default methods
      module DefaultApiMethod
        # This is the default api that is used by assert_api_conform
        # :default is the default name that is used if you don't pass an `api:` option to `OpenapiFirst::Test.register`
        # This is overwritten if you pass an `api:` option to `include OpenapiFirst::Test::Methods[…]`
        def openapi_first_default_api
          klass = self.class
          if klass.respond_to?(:metadata) && klass.metadata[:api]
            klass.metadata[:api]
          else
            :default
          end
        end
      end

      # @api private
      module AssertionMethod
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
end

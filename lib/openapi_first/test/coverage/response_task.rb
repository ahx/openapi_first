# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  module Test
    module Coverage
      # @visibility private
      class ResponseTask
        extend Forwardable

        def_delegators :@response, :status, :content_type, :key

        def initialize(response_definition)
          @response = response_definition
          @responded = false
        end

        attr_reader :response

        def track(_response)
          @responded = true
        end

        def request?
          false
        end

        def response?
          true
        end

        def responded?
          @responded == true
        end

        alias finished? responded?

        def unfinished?
          !finished?
        end
      end
    end
  end
end

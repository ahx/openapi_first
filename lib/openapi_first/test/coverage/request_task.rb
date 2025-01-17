# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  module Test
    module Coverage
      # @visibility private
      class RequestTask
        extend Forwardable

        def_delegators :@request, :path, :request_method, :content_type

        def initialize(request_definition, responses:)
          @request = request_definition
          @responses = responses
          @requested = false
        end

        attr_reader :request, :responses

        def track(_request)
          @requested = true
        end

        def request?
          true
        end

        def response?
          false
        end

        def requested?
          @requested == true
        end

        alias finished? requested?

        def unfinished?
          !finished?
        end
      end
    end
  end
end

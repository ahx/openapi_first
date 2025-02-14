# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  module Test
    module Coverage
      # @visibility private
      class RequestTask
        extend Forwardable

        def_delegators :@request, :path, :request_method, :content_type

        def initialize(request_definition)
          @request = request_definition
          @requested = false
        end

        attr_reader :request

        def track(validated_request)
          @requested = true
          @valid ||= true if validated_request.valid?
        end

        def requested?
          @requested == true
        end

        def any_valid_request?
          @valid == true
        end

        def finished?
          requested? && any_valid_request?
        end
      end
    end
  end
end

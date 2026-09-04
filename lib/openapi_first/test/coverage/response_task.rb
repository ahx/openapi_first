# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  module Test
    module Coverage
      # @visibility private
      class ResponseTask
        extend Forwardable

        def_delegators :@response, :status, :content_type, :key

        def initialize(response_definition, skipped: false)
          @response = response_definition
          @skipped = skipped
          @responded = false
          @last_error_message = nil
        end

        attr_reader :response, :last_error_message

        def track(validated_response)
          @responded = true
          @valid ||= true if validated_response.valid?
          @last_error_message = validated_response.error.exception_message unless validated_response.valid?
        end

        def skipped?
          @skipped == true
        end

        def responded?
          @responded == true
        end

        def any_valid_response?
          @valid == true
        end

        def finished?
          responded? && any_valid_response?
        end
      end
    end
  end
end

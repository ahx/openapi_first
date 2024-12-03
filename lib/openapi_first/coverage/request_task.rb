# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  module Coverage
    class RequestTask
      extend Forwardable

      def_delegators :@request, :path, :request_method, :content_type

      def initialize(request, responses:)
        @request = request
        @responses = responses
        @responses.freeze
      end

      attr_reader :responses

      def check
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

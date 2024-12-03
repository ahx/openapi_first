# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  module Coverage
    class ResponseTask
      extend Forwardable

      def_delegators :@response, :status, :content_type, :key

      def initialize(response)
        @response = response
      end

      def check
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

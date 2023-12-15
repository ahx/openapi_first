# frozen_string_literal: true

require_relative 'runtime_response'

module OpenapiFirst
  class Definition
    # RuntimeRequest represents how an incoming request (Rack::Request) matches a request definition.
    class RuntimeRequest
      def initialize(path_item:, operation:, path_params:)
        @path_item = path_item
        @operation = operation
        @path_params = path_params
      end

      attr_reader :operation, :path_item, :path_params

      def response(rack_response)
        RuntimeResponse.new(operation, rack_response)
      end
    end
  end
end

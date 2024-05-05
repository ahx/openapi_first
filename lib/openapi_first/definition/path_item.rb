# frozen_string_literal: true

require 'forwardable'
require_relative 'operation'
require_relative 'path_template'

module OpenapiFirst
  class Definition
    # A pathItem as defined in the OpenAPI document.
    class PathItem
      extend Forwardable

      def initialize(path, path_item_object)
        @path = path
        @path_item_object = path_item_object
        @path_template = PathTemplate.new(path)
        @requests = operations.each_with_object({}) { |op, result| result[op.request_method.upcase] = op }
      end

      attr_reader :path, :requests

      def_delegator :@path_template, :match

      def_delegators :@path_item_object,
                     :[]

      METHODS = %w[get head post put patch delete trace options].freeze
      private_constant :METHODS

      def operation(request_method)
        requests[request_method.upcase]
      end

      def operations
        @operations ||= @path_item_object.slice(*METHODS).keys.map do |request_method|
          operation_object = @path_item_object[request_method]
          Operation.new(self, request_method, operation_object)
        end
      end
    end
  end
end

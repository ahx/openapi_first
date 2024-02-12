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
      end

      attr_reader :path

      def_delegator :@path_template, :match

      def operation(request_method)
        return unless @path_item_object[request_method]

        Operation.new(@path, request_method, @path_item_object)
      end

      METHODS = %w[get head post put patch delete trace options].freeze
      private_constant :METHODS

      def operations
        @operations ||= @path_item_object.slice(*METHODS).keys.map { |method| operation(method) }
      end
    end
  end
end

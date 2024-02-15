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
        operation_object = @path_item_object[request_method]
        return unless operation_object

        Operation.new(path, request_method, operation_object)
      end

      METHODS = %w[get head post put patch delete trace options].freeze
      private_constant :METHODS

      def operations
        @operations ||= @path_item_object.slice(*METHODS).keys.map { |method| operation(method) }
      end

      %w[query path header cookie].each do |location|
        define_method("#{location}_parameters") do
          all_parameters[location]
        end
      end

      private

      attr_reader :all_parameters
    end
  end
end

# frozen_string_literal: true

require_relative 'operation'

module OpenapiFirst
  class PathItem
    def initialize(path, path_item_object, openapi_version:)
      @path = path
      @path_item_object = path_item_object
      @openapi_version = openapi_version
    end

    attr_reader :path

    def find_operation(request_method)
      return unless @path_item_object[request_method]

      Operation.new(
        @path, request_method, @path_item_object, openapi_version: @openapi_version
      )
    end
  end
end

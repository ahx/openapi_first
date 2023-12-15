# frozen_string_literal: true

require 'mustermann/template'
require_relative 'definition/path_item'
require_relative 'definition/runtime_request'

module OpenapiFirst
  # Represents an OpenAPI API Description document
  class Definition
    attr_reader :filepath, :paths, :openapi_version

    def initialize(resolved, filepath)
      @filepath = filepath
      @paths = resolved['paths']
      @openapi_version = detect_version(resolved)
    end

    def request(rack_request)
      path_item, path_params = find_path_item_and_params(rack_request.path)
      operation = path_item&.operation(rack_request.request_method.downcase)
      RuntimeRequest.new(
        path_item:,
        operation:,
        path_params:
      )
    end

    def response(rack_request, rack_response)
      request(rack_request).response(rack_response)
    end

    def operations
      @operations ||= path_items.flat_map(&:operations)
    end

    def path(pathname)
      return unless paths.key?(pathname)

      PathItem.new(pathname, paths[pathname], openapi_version:)
    end

    private

    def path_items
      @path_items ||= paths.flat_map do |path, path_item_object|
        PathItem.new(path, path_item_object, openapi_version:)
      end
    end

    def find_path_item_and_params(request_path)
      matches = paths.each_with_object([]) do |kv, result|
        path, path_item_object = kv
        template = Mustermann::Template.new(path)
        path_params = template.params(request_path)
        next unless path_params

        path_item = PathItem.new(path, path_item_object, openapi_version:)
        result << [path_item, path_params]
      end
      # Thanks to open ota42y/openapi_parser for this part
      matches.min_by { |match| match[1].size }
    end

    def detect_version(resolved)
      (resolved['openapi'] || resolved['swagger'])[0..2]
    end
  end
end

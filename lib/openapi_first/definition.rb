# frozen_string_literal: true

require 'mustermann/template'
require_relative 'path_item'

module OpenapiFirst
  # Represents an OpenAPI API Description document
  class Definition
    attr_reader :filepath, :paths, :openapi_version

    def initialize(resolved, filepath)
      @filepath = filepath
      @paths = resolved['paths']
      @openapi_version = detect_version(resolved)
    end

    # @param request_path String
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

    def operations
      methods = %w[get head post put patch delete trace options]
      @operations ||= paths.flat_map do |path, path_item_object|
        path_item = PathItem.new(path, path_item_object, openapi_version:)
        path_item_object.slice(*methods).keys.map { |method| path_item.find_operation(method) }
      end
    end

    private

    def detect_version(resolved)
      (resolved['openapi'] || resolved['swagger'])[0..2]
    end
  end
end

# frozen_string_literal: true

require_relative 'operation'

module OpenapiFirst
  # Represents an OpenAPI API Description document
  class Definition
    attr_reader :filepath, :operations

    def initialize(resolved, filepath)
      @filepath = filepath
      methods = %w[get head post put patch delete trace options]
      @operations = resolved['paths'].flat_map do |path, path_item|
        path_item.slice(*methods).map do |request_method, _operation_object|
          Operation.new(path, request_method, path_item, openapi_version: detect_version(resolved))
        end
      end
    end

    private

    def detect_version(resolved)
      (resolved['openapi'] || resolved['swagger'])[0..2]
    end
  end
end

# frozen_string_literal: true

require 'r2ree'

module OpenapiFirst
  class Definition
    def initialize(parsed)
      @spec = parsed
      normalized_paths = @spec.paths.map do |path|
        path.path.gsub('{', ':').gsub('}','')
      end
      @path_tree = R2ree.new(normalized_paths)
      @paths = @spec.paths
    end

    def operations
      @spec.endpoints
    end

    def find_operation!(request)
      path_index = @path_tree.find(request.path)
      raise OasParser::PathNotFound if path_index == -1
      @paths[path_index]
        .endpoint_by_method(request.request_method.downcase)
    end

    def find_operation(request)
      find_operation!(request)
    rescue OasParser::PathNotFound, OasParser::MethodNotFound
      nil
    end
  end
end

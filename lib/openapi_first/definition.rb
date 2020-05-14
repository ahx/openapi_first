# frozen_string_literal: true

require_relative 'operation'

module OpenapiFirst
  class Definition
    attr_reader :filepath

    def initialize(parsed)
      @filepath = parsed.path
      @spec = parsed
    end

    def operations
      @spec.endpoints.map { |e| Operation.new(e) }
    end

    def find_operation!(request)
      @spec
        .path_by_path(request.path)
        .endpoint_by_method(request.request_method.downcase)
    end

    def find_operation(request)
      find_operation!(request)
    rescue OasParser::PathNotFound, OasParser::MethodNotFound
      nil
    end
  end
end

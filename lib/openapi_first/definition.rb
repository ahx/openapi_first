# frozen_string_literal: true

module OpenapiFirst
  class Definition
    def initialize(parsed)
      @spec = parsed
    end

    def operations
      @spec.endpoints
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

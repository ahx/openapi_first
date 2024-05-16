# frozen_string_literal: true

require_relative 'definition/path_template'

module OpenapiFirst
  # Router maps a request (method, path) to a PathItem and Operation in the OpenAPI API description.
  class Router
    Template = Definition::PathTemplate

    Match = Data.define(:route, :params, :error)
    NOT_FOUND = Match.new(route: nil, params: nil, error: Failure.new(:not_found))

    # @param requests List of path item definitions
    def initialize
      @static = {}
      @dynamic = {}
      @templates = {}
    end

    def add_route(request_method, path, route)
      path_item = if Template.template?(path)
                    @templates[path] ||= Template.new(path)
                    @dynamic[path] ||= {}
                  else
                    @static[path] ||= {}
                  end
      path_item[request_method.upcase] ||= route
    end

    # Return all request objects that match the given path and request method
    def match(request_method, path)
      path_item, params = find_path_item(path)
      return NOT_FOUND unless path_item

      route = path_item[request_method]
      return Match.new(route:, params:, error: Failure.new(:method_not_allowed)) unless route

      Match.new(route:, params:, error: nil)
    end

    private

    def find_path_item(path)
      found = @static[path]
      return [found, {}] if found

      @dynamic.find do |template_string, request|
        params = @templates[template_string].match(path)
        return [request, params] if params
      end
    end
  end
end

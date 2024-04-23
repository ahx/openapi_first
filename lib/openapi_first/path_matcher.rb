# frozen_string_literal: true

module OpenapiFirst
  # Indexes the given path objects and returns the first object that matches
  class PathMatcher
    def initialize(requests, template_class: Definition::PathTemplate)
      @static = {}
      @dynamic = {}
      requests.each do |request|
        pathname = request.path
        if template_class.template?(pathname)
          @dynamic[template_class.new(pathname)] = request
        else
          @static[pathname] = request
        end
      end
    end

    # Matches a path name against the defined paths
    # @param [String] path
    # @return Array<String, Hash>
    def call(pathname)
      found = @static[pathname]
      return [found, {}] if found

      @dynamic.find do |template, request|
        params = template.match(pathname)
        return [request, params] if params
      end
    end
  end
end

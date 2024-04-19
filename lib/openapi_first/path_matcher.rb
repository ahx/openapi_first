# frozen_string_literal: true

module OpenapiFirst
  # Indexes the given path objects by `#to_s` and matches by `#match`
  class PathMatcher
    def initialize(paths, template_class: Definition::PathTemplate)
      @static = {}
      @dynamic = []
      paths.each do |path|
        pathname = path.to_s
        if template_class.template?(pathname)
          @dynamic << template_class.new(pathname)
        else
          @static[pathname] = path
        end
      end
    end

    # Matches a path name against the defined paths
    # @param [String] path
    # @return Array<String, Hash>
    def call(pathname)
      found = @static[pathname]
      return [found, {}] if found

      @dynamic.find do |path|
        params = path.match(pathname)
        return [path.to_s, params] if params
      end
    end
  end
end

# frozen_string_literal: true

require_relative 'path_template'

module OpenapiFirst
  # Router maps a request (method, path, content_type) to a request definition.
  class Router
    Template = Definition::PathTemplate

    Match = Data.define(:request_definition, :params, :error)
    NOT_FOUND = Match.new(request_definition: nil, params: nil, error: Failure.new(:not_found))

    # @param requests List of path item definitions
    def initialize
      @static = {}
      @dynamic = {}
      @templates = {}
    end

    def route(request_method, path, to:, content_type: nil)
      path_item = if Template.template?(path)
                    @templates[path] ||= Template.new(path)
                    @dynamic[path] ||= {}
                  else
                    @static[path] ||= {}
                  end
      (path_item[request_method.upcase] ||= ContentMatcher.new).add(content_type, to)
    end

    # Return all request objects that match the given path and request method
    def match(request_method, path, content_type: nil)
      path_item, params = find_path_item(path)
      return NOT_FOUND unless path_item

      content = path_item[request_method]
      return Match.new(request_definition: nil, params:, error: Failure.new(:method_not_allowed)) unless content

      request_definition = content&.match(content_type)
      unless request_definition
        message = "#{content_type_err(content_type)} Content-Type should be #{content.defined_content_types.join(' or ')}."
        error = Failure.new(:unsupported_media_type, message:)
        return Match.new(request_definition: nil, params:, error:)
      end

      Match.new(request_definition:, params:, error: nil)
    end

    private

    def content_type_err(content_type)
      return 'Content-Type must not be empty.' if content_type.nil? || content_type.empty?

      "Content-Type #{content_type} is not defined."
    end

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

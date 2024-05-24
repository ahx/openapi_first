# frozen_string_literal: true

require 'forwardable'
require_relative 'router/path_template'
require_relative 'router/response_matcher'

module OpenapiFirst
  # Router can map requests / responses to their API definition
  class Router
    # @visibility private
    class RequestMatch < Data.define(:request_definition, :params, :error, :responses)
      def match_response(status:, content_type:)
        responses&.match(status, content_type)
      end
    end

    NOT_FOUND = RequestMatch.new(request_definition: nil, params: nil, responses: nil, error: Failure.new(:not_found))
    private_constant :NOT_FOUND

    # @param requests List of path item definitions
    def initialize
      @static = {}
      @dynamic = {}
      @templates = {}
    end

    def add_request(request, request_method:, path:, content_type: nil)
      (node_at(path, request_method)[:requests] ||= ContentMatcher.new).add(content_type, request)
    end

    def add_response(response, request_method:, path:, status:, response_content_type: nil)
      (node_at(path, request_method)[:responses] ||= ResponseMatcher.new).add_response(status, response_content_type,
                                                                                       response)
    end

    # Return all request objects that match the given path and request method
    def match(request_method, path, content_type: nil)
      path_item, params = find_path_item(path)
      return NOT_FOUND unless path_item

      content = path_item.dig(request_method, :requests)
      return NOT_FOUND.with(error: Failure.new(:method_not_allowed)) unless content

      request_definition = content&.match(content_type)
      unless request_definition
        message = "#{content_type_err(content_type)} Content-Type should be #{content.defined_content_types.join(' or ')}."
        return NOT_FOUND.with(error: Failure.new(:unsupported_media_type, message:))
      end

      responses = path_item.dig(request_method, :responses)
      RequestMatch.new(request_definition:, params:, error: nil, responses:)
    end

    private

    def node_at(path, request_method)
      path_item = if PathTemplate.template?(path)
                    @templates[path] ||= PathTemplate.new(path)
                    @dynamic[path] ||= {}
                  else
                    @static[path] ||= {}
                  end
      path_item[request_method.upcase] ||= {}
    end

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

# frozen_string_literal: true

require_relative 'path_matcher'

module OpenapiFirst
  # Indexes OpenapiFirst::Request objects by path and request method
  class Router
    Match = Data.define(:path_item, :operation, :params, :error) do
      def error?
        !error.nil?
      end
    end

    PATH_NOT_FOUND = Match.new(error: Failure.new(:not_found), path_item: nil, operation: nil, params: nil)

    # @param requests List of path item definitions
    def initialize(path_items)
      @path_matcher = PathMatcher.new(path_items)
    end

    # Return all request objects that match the given path and request method
    def match(request_method, path)
      match = @path_matcher.call(path)
      return PATH_NOT_FOUND unless match

      path_item, params = match
      operation = path_item.requests[request_method]
      error = Failure.new(:method_not_allowed) unless operation
      Match.new(path_item:, operation:, params:, error:)
    end
  end
end

# frozen_string_literal: true

require_relative 'path_matcher'

module OpenapiFirst
  # Indexes OpenapiFirst::Request objects by path and request method
  class Router
    Match = Data.define(:path_item, :operation, :params) do
      def error?
        false
      end
    end

    Mismatch = Data.define(:error) do
      def error?
        true
      end
    end

    PATH_NOT_FOUND = Mismatch.new(Failure.new(:not_found))

    # @param requests List of path item definitions
    def initialize(path_items)
      @path_matcher = PathMatcher.new(path_items)
    end

    # Return all request objects that match the given path and request method
    def match(request_method, path)
      match = @path_matcher.call(path)
      return PATH_NOT_FOUND unless match

      path_item, params = match
      request = path_item.requests[request_method]
      if request
        Match.new(path_item, request, params)
      else
        Mismatch.new(Failure.new(:method_not_allowed))
      end
    end
  end
end

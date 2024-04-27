require_relative 'path_matcher'

module OpenapiFirst
  # Indexes OpenapiFirst::Request objects by path and request method
  class Router
    Mismatch = Data.define(:path, :request_method, :error) do
      def error?
        true
      end
    end

    PATH_NOT_FOUND_MISMATCH = Mismatch.new(nil, nil, Failure.new(:not_found))
    NOT_FOUND = [PATH_NOT_FOUND_MISMATCH, nil].freeze

    # @param requests List of path item definitions
    def initialize(path_items)
      @path_matcher = PathMatcher.new(path_items)
    end

    # Return all request objects that match the given path and request method
    def match(request_method, path)
      match = @path_matcher.call(path)
      return NOT_FOUND unless match

      path_item = match[0]
      request = path_item.requests[request_method]
      match[0] = request || Mismatch.new(path_item.path, request_method, Failure.new(:method_not_allowed))
      match
    end
  end
end

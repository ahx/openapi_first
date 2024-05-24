# frozen_string_literal: true

module OpenapiFirst
  class Router
    # Finds the object that matches the content type.
    class ContentMatcher
      def initialize
        @results = {}
      end

      def add(content_type, object)
        @results[content_type] = object
      end

      def defined_content_types
        @results.keys
      end

      def match(content_type)
        return @results[nil] if content_type.nil? || content_type.empty?

        @results.fetch(content_type) do
          type = content_type.split(';')[0]
          @results[type] || @results["#{type.split('/')[0]}/*"] || @results['*/*'] || @results[nil]
        end
      end
    end
  end
end

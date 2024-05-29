# frozen_string_literal: true

module OpenapiFirst
  class Router
    # Finds the object that matches the content type.
    class ContentMatcher
      include Enumerable

      def initialize
        @results = {}
      end

      extend Forwardable
      def_delegators :@results, :values, :keys, :[]=
      def_delegator :@results, :each_value, :each

      def [](content_type)
        return @results[nil] if content_type.nil? || content_type.empty?

        @results.fetch(content_type) do
          type = content_type.split(';')[0]
          @results[type] || @results["#{type.split('/')[0]}/*"] || @results['*/*'] || @results[nil]
        end
      end
    end
  end
end

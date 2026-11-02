# frozen_string_literal: true

require_relative '../path_template'

module OpenapiFirst
  class Router
    # Matches one path segment against a segment of a path template that mixes literals and variables
    # @visibility private
    class SegmentPattern
      def initialize(segment)
        @pattern = build_pattern(segment)
      end

      # @return [Array<String>, nil] the variable values in order of appearance, or nil
      def match(segment)
        @pattern.match(segment)&.captures
      end

      private

      def build_pattern(segment)
        parts = segment.split(PathTemplate::VARIABLE).each_slice(2).map do |literal, name|
          "#{Regexp.escape(literal)}#{'([^/?#]+)' if name}"
        end
        /\A#{parts.join}\z/
      end
    end
  end
end

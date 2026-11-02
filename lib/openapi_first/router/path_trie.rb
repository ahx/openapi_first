# frozen_string_literal: true

require 'rack/utils'
require_relative '../path_template'
require_relative 'segment_pattern'

module OpenapiFirst
  class Router
    # @visibility private
    class PathTrie
      def initialize
        @static = {}
        @partial = {}
        @variable = nil
        @leaf = nil
      end

      def add(template, value)
        names = PathTemplate.variable_names(template)
        node = template.split('/', -1).reduce(self) { |parent, segment| parent.child(segment) }
        node.leaf ||= [value, names]
      end

      def match(path)
        values = []
        value, names = find(path.split('/', -1), 0, values)
        return unless value

        values.map! { decode(_1) } if path.include?('%')
        [value, names.zip(values).to_h]
      end

      def find(segments, index, values)
        return @leaf if index == segments.size

        @static[segments[index]]&.find(segments, index + 1, values) ||
          find_partial(segments, index, values) ||
          find_variable(segments, index, values)
      end

      protected

      attr_accessor :leaf

      def child(segment)
        return @variable ||= PathTrie.new if PathTemplate.variable?(segment)
        return partial_child(segment) if PathTemplate.template?(segment)

        @static[segment] ||= PathTrie.new
      end

      private

      def decode(value)
        decoded = Rack::Utils.unescape_path(value).force_encoding(Encoding::UTF_8)
        decoded.valid_encoding? ? decoded : value
      end

      def find_partial(segments, index, values)
        @partial.each_value do |pattern, node|
          captures = pattern.match(segments[index])
          next unless captures

          values.concat(captures)
          found = node.find(segments, index + 1, values)
          return found if found

          values.pop(captures.size)
        end
        nil
      end

      def find_variable(segments, index, values)
        segment = segments[index]
        return if @variable.nil? || segment.empty?

        values << segment
        found = @variable.find(segments, index + 1, values)
        values.pop unless found
        found
      end

      def partial_child(segment)
        @partial[segment] ||= [SegmentPattern.new(segment), PathTrie.new]
        @partial = @partial.sort_by.with_index { |(key, _), i| [-literal_length(key), i] }.to_h
        @partial[segment].last
      end

      def literal_length(segment)
        segment.gsub(PathTemplate::VARIABLE, '').length
      end
    end
  end
end

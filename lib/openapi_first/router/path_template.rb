# frozen_string_literal: true

module OpenapiFirst
  class Router
    # @visibility private
    class PathTemplate
      # See also https://spec.openapis.org/oas/v3.1.0#path-templating
      TEMPLATE_EXPRESSION = /(\{[^{}]+\})/

      def self.template?(string)
        string.include?('{')
      end

      def initialize(template)
        @template = template
        @pattern = build_pattern(template)
      end

      def to_s
        @template
      end

      def match(path)
        return {} if path == @template

        matches = path.match(@pattern)
        return unless matches

        matches.named_captures
      end

      private

      def build_pattern(template)
        parts = template.split(TEMPLATE_EXPRESSION).map! do |part|
          if part.start_with?('{')
            "(?<#{part[1..-2]}>[^/?#]+)"
          else
            Regexp.escape(part)
          end
        end

        /^#{parts.join}$/
      end
    end
  end
end

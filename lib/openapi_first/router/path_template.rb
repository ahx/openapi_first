# frozen_string_literal: true

module OpenapiFirst
  class Router
    # @visibility private
    class PathTemplate
      # See also https://spec.openapis.org/oas/v3.1.0#path-templating
      TEMPLATE_EXPRESSION = /(\{[^{}]+\})/
      TEMPLATE_EXPRESSION_NAME = /\{([^{}]+)\}/
      ALLOWED_PARAMETER_CHARACTERS = %r{([^/?#]+)}

      def self.template?(string)
        string.include?('{')
      end

      def initialize(template, path_parameters, use_patterns_for_path_matching)
        @template = template
        @path_parameters = path_parameters
        @use_patterns_for_path_matching = use_patterns_for_path_matching
        @names = template.scan(TEMPLATE_EXPRESSION_NAME).flatten
        @pattern = build_pattern(template)
      end

      def to_s
        @template
      end

      def match(path)
        return {} if path == @template
        return if @names.empty?

        matches = path.match(@pattern)
        return unless matches

        values = matches.captures
        @names.zip(values).to_h
      end

      private

      def build_pattern(template)
        parts = template.split(TEMPLATE_EXPRESSION).map! do |part|
          if part.start_with?('{')
            name = part.match(TEMPLATE_EXPRESSION_NAME)[1]
            parameter = @path_parameters.find { |p| p['name'] == name }
            if @use_patterns_for_path_matching && parameter&.[]('schema')&.[]('pattern')
              single_capturing_group(parameter['schema']['pattern'])
            else
              ALLOWED_PARAMETER_CHARACTERS
            end
          else
            Regexp.escape(part)
          end
        end

        %r{^#{parts.join}/?$}
      end

      def single_capturing_group(pattern)
        %r{(#{pattern.gsub(/(?<!\\)\((?!\?[:\-!=])/) { "(?:" }})}
      end
    end
  end
end

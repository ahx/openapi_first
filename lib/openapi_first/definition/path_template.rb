# frozen_string_literal: true

module OpenapiFirst
  # @visibility private
  class PathTemplate
    def initialize(template)
      @template = template
      @names = template.scan(NAMES_PAT).flatten
      parts = template.split(CURLIES_PAT).map! do |part|
        if part.start_with?('{')
          part.sub(/{.*?}/, '([^/?#]+)')
        else
          Regexp.escape(part)
        end
      end
      @pattern = %r{^#{parts.join}/?$}
    end

    CURLIES_PAT = /(\{[^}]+\})/
    NAMES_PAT = /\{([^}]+)\}/

    def match(path)
      return {} if path == @template
      return if @names.empty?

      matches = path.match(@pattern)
      return unless matches

      values = matches.captures
      return if values.length != @names.length

      @names.zip(values).to_h
    end
  end
end

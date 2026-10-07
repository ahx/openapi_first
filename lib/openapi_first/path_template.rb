# frozen_string_literal: true

module OpenapiFirst
  # Path templating as described in https://spec.openapis.org/oas/v3.1.0#path-templating
  # @visibility private
  module PathTemplate
    VARIABLE = /\{(?<name>[^{}]+)\}/
    SEGMENT_VARIABLE = /\A#{VARIABLE}\z/

    # @return [Boolean] whether the path contains at least one variable
    def self.template?(path)
      path.match?(VARIABLE)
    end

    # @return [Boolean] whether the path segment consists of exactly one variable
    def self.variable?(segment)
      segment.match?(SEGMENT_VARIABLE)
    end

    # @return [Array<String>] the variable names in order of appearance
    def self.variable_names(template)
      template.scan(VARIABLE).flatten
    end

    # Replaces each variable with the value the block returns for its name
    def self.expand(template)
      template.gsub(VARIABLE) { yield Regexp.last_match(:name) }
    end
  end
end

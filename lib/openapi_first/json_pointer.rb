# frozen_string_literal: true

module OpenapiFirst
  # Functions to handle JSON Pointers
  # @!visibility private
  module JsonPointer
    ESCAPE_CHARS = { '~' => '~0', '/' => '~1', '+' => '%2B' }.freeze
    ESCAPE_REGEX = Regexp.union(ESCAPE_CHARS.keys)

    module_function

    def append(root, *tokens)
      "#{root}/" + tokens.map do |token|
        escape_json_pointer_token(token)
      end.join('/')
    end

    def escape_json_pointer_token(token)
      token.gsub(ESCAPE_REGEX, ESCAPE_CHARS)
    end
  end
end

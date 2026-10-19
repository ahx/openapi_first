# frozen_string_literal: true

# This tries to load MultiJson if available to keep compatibility
# with MultiJson

begin
  require 'multi_json'

  module OpenapiFirst
    # Compatibility with MultiJson
    # @visibility private
    module JSON
      if defined?(::MultiJSON)
        # multi_json >= 1.21.0
        ParserError = MultiJSON::ParseError
        def self.parse(string) = MultiJSON.parse(string)
        def self.generate(object) = MultiJSON.generate(object)
      else
        # multi_json < 1.21.0
        ParserError = MultiJson::ParseError
        def self.parse(string) = MultiJson.load(string)
        def self.generate(object) = MultiJson.dump(object)
      end
    end
  end
rescue LoadError
  require 'json'
end

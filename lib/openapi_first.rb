require 'oas_parser'
require 'openapi_first/version'

module OpenapiFirst
  def self.load(spec_path)
    OasParser::Definition.resolve(spec_path)
  end

  class Error < StandardError; end
  # Your code goes here...
end

require 'oas_parser'
require 'openapi_first/version'
require 'openapi_first/response_validator'
require 'openapi_first/test_coverage'

module OpenapiFirst
  def self.load(spec_path)
    OasParser::Definition.resolve(spec_path)
  end

  class Error < StandardError; end
  # Your code goes here...
end

require 'oas_parser'
require 'openapi_first/version'

module OpenapiFirst
  OPERATION = 'openapi_first.operation'.freeze
  REQUEST_BODY = 'openapi_first.parsed_request_body'.freeze
  QUERY_PARAMS = 'openapi_first.query_params'.freeze

  def self.load(spec_path)
    OasParser::Definition.resolve(spec_path)
  end

  class Error < StandardError; end
  # Your code goes here...
end

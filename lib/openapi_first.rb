# frozen_string_literal: true

require 'yaml'
require 'json_refs'
require_relative 'openapi_first/definition'
require_relative 'openapi_first/version'
require_relative 'openapi_first/errors'
require_relative 'openapi_first/router'
require_relative 'openapi_first/request_validation'
require_relative 'openapi_first/response_validator'
require_relative 'openapi_first/response_validation'

module OpenapiFirst
  # The OpenAPI operation for the current request
  OPERATION = 'openapi.operation'

  # Merged path and query parameters
  PARAMS = 'openapi.params'

  # Parsed header parameters, except for Content-Type, Accept and Authorization
  HEADERS = 'openapi.headers'

  # The parsed request body
  REQUEST_BODY = 'openapi.parsed_request_body'

  def self.load(spec_path, only: nil)
    resolved = Dir.chdir(File.dirname(spec_path)) do
      content = YAML.load_file(File.basename(spec_path))
      JsonRefs.call(content, resolve_local_ref: true, resolve_file_ref: true)
    end
    resolved['paths'].filter!(&->(key, _) { only.call(key) }) if only
    Definition.new(resolved, spec_path)
  end
end

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
  OPERATION = 'openapi.operation'
  # The unconverted path parameters before they are converted to the types defined in the API description
  RAW_PATH_PARAMS = 'openapi.raw_path_params'

  PARAMS = 'openapi.params'
  REQUEST_BODY = 'openapi.parsed_request_body'
  HANDLER = 'openapi_first.handler'

  def self.env
    ENV['RACK_ENV'] || ENV['HANAMI_ENV'] || ENV.fetch('RAILS_ENV', nil)
  end

  def self.load(spec_path, only: nil)
    resolved = Dir.chdir(File.dirname(spec_path)) do
      content = YAML.load_file(File.basename(spec_path))
      JsonRefs.call(content, resolve_local_ref: true, resolve_file_ref: true)
    end
    resolved['paths'].filter!(&->(key, _) { only.call(key) }) if only
    Definition.new(resolved, spec_path)
  end
end

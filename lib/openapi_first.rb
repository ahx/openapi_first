# frozen_string_literal: true

require 'yaml'
require 'json_refs'
require_relative 'openapi_first/errors'
require_relative 'openapi_first/configuration'
require_relative 'openapi_first/plugins'
require_relative 'openapi_first/definition'
require_relative 'openapi_first/version'
require_relative 'openapi_first/error_response'
require_relative 'openapi_first/request_validation'
require_relative 'openapi_first/response_validation'

module OpenapiFirst
  extend Plugins

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end

  # An instance of RuntimeRequest
  REQUEST = 'openapi.request'

  def self.load(spec_path, only: nil)
    resolved = Dir.chdir(File.dirname(spec_path)) do
      content = YAML.load_file(File.basename(spec_path))
      JsonRefs.call(content, resolve_local_ref: true, resolve_file_ref: true)
    end
    resolved['paths'].filter!(&->(key, _) { only.call(key) }) if only
    Definition.new(resolved, spec_path)
  end
end

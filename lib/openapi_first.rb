# frozen_string_literal: true

require 'yaml'
require 'multi_json'
require 'json_refs'
require_relative 'openapi_first/errors'
require_relative 'openapi_first/configuration'
require_relative 'openapi_first/plugins'
require_relative 'openapi_first/definition'
require_relative 'openapi_first/version'
require_relative 'openapi_first/error_response'
require_relative 'openapi_first/middlewares/response_validation'
require_relative 'openapi_first/middlewares/request_validation'

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

  # Key in rack to find instance of RuntimeRequest
  REQUEST = 'openapi.request'

  # Load and dereference an OpenAPI spec file
  def self.load(filepath, only: nil)
    resolved = bundle(filepath)
    parse(resolved, only:, filepath:)
  end

  # Parse a dereferenced Hash
  def self.parse(resolved, only: nil, filepath: nil)
    resolved['paths'].filter!(&->(key, _) { only.call(key) }) if only
    Definition.new(resolved, filepath)
  end

  def self.bundle(filepath)
    Bundle.resolve(filepath)
  end

  module Bundle
    def self.resolve(spec_path)
      Dir.chdir(File.dirname(spec_path)) do
        content = load_file(File.basename(spec_path))
        JsonRefs.call(content, resolve_local_ref: true, resolve_file_ref: true)
      end
    end

    def self.load_file(spec_path)
      return MultiJson.load(File.read(spec_path)) if File.extname(spec_path) == '.json'

      YAML.unsafe_load_file(spec_path)
    end
  end
end

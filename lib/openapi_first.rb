# frozen_string_literal: true

require 'yaml'
require 'multi_json'
require_relative 'openapi_first/json_refs'
require_relative 'openapi_first/errors'
require_relative 'openapi_first/configuration'
require_relative 'openapi_first/plugins'
require_relative 'openapi_first/definition'
require_relative 'openapi_first/version'
require_relative 'openapi_first/error_response'
require_relative 'openapi_first/middlewares/response_validation'
require_relative 'openapi_first/middlewares/request_validation'

# OpenapiFirst is a toolchain to build HTTP APIS based on OpenAPI API descriptions.
module OpenapiFirst
  extend Plugins

  class << self
    # @return [Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # @return [Configuration]
    # @yield [Configuration]
    def configure
      yield configuration
    end
  end

  # Key in rack to find instance of RuntimeRequest
  REQUEST = 'openapi.request'

  # Load and dereference an OpenAPI spec file
  # @return [Definition]
  def self.load(filepath, only: nil)
    resolved = Bundle.resolve(filepath)
    parse(resolved, only:, filepath:)
  end

  # Parse a dereferenced Hash
  # @return [Definition]
  def self.parse(resolved, only: nil, filepath: nil)
    resolved['paths'].filter!(&->(key, _) { only.call(key) }) if only
    Definition.new(resolved, filepath)
  end

  # @!visibility private
  module Bundle
    def self.resolve(spec_path)
      JsonRefs.load(spec_path)
    end
  end
end

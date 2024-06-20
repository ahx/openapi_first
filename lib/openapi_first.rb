# frozen_string_literal: true

require 'yaml'
require 'multi_json'
require_relative 'openapi_first/json_refs'
require_relative 'openapi_first/errors'
require_relative 'openapi_first/configuration'
require_relative 'openapi_first/definition'
require_relative 'openapi_first/version'
require_relative 'openapi_first/schema'
require_relative 'openapi_first/error_responses'
require_relative 'openapi_first/error_response'
require_relative 'openapi_first/error_responses/default'
require_relative 'openapi_first/error_responses/jsonapi'
require_relative 'openapi_first/middlewares/response_validation'
require_relative 'openapi_first/middlewares/request_validation'

# OpenapiFirst is a toolchain to build HTTP APIS based on OpenAPI API descriptions.
module OpenapiFirst
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

  # Key in rack to find instance of Request
  REQUEST = 'openapi.request'
  FAILURE = :openapi_first_validation_failure

  # Load and dereference an OpenAPI spec file
  # @return [Definition]
  def self.load(filepath, only: nil, &)
    raise FileNotFoundError, "File not found: #{filepath}" unless File.exist?(filepath)

    resolved = Bundle.resolve(filepath)
    parse(resolved, only:, filepath:, &)
  end

  # Parse a dereferenced Hash
  # @return [Definition]
  def self.parse(resolved, only: nil, filepath: nil, &)
    resolved['paths'].filter!(&->(key, _) { only.call(key) }) if only
    Definition.new(resolved, filepath, &)
  end

  # @!visibility private
  module Bundle
    def self.resolve(spec_path)
      @file_cache ||= {}
      @file_cache[File.expand_path(spec_path).to_sym] ||= JsonRefs.load(spec_path)
    end
  end
end

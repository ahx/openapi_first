# frozen_string_literal: true

require 'yaml'
require 'oas_parser'
require 'openapi_first/definition'
require 'openapi_first/version'
require 'openapi_first/router'
require 'openapi_first/query_parameter_validation'
require 'openapi_first/request_body_validation'
require 'openapi_first/response_validator'
require 'openapi_first/operation_resolver'
require 'openapi_first/app'

module OpenapiFirst
  OPERATION = 'openapi_first.operation'
  PATH_PARAMS = 'openapi_first.path_params'
  REQUEST_BODY = 'openapi_first.parsed_request_body'
  QUERY_PARAMS = 'openapi_first.query_params'

  def self.load(spec_path, only: nil)
    content = YAML.load_file(spec_path)
    raw = OasParser::Parser.new(spec_path, content).resolve
    raw['paths'].filter!(&->(key, _) { only.call(key) }) if only
    parsed = OasParser::Definition.new(raw, spec_path)
    Definition.new(parsed)
  end

  def self.app(spec, namespace:)
    spec = OpenapiFirst.load(spec) if spec.is_a?(String)
    App.new(spec, namespace: namespace)
  end

  def self.middleware(spec, namespace:)
    spec = OpenapiFirst.load(spec) if spec.is_a?(String)
    AppWithOptions.new(spec, namespace: namespace)
  end

  class AppWithOptions
    def initialize(*options)
      @options = options
    end

    def new(app)
      App.new(app, *@options)
    end
  end

  class Error < StandardError; end
  # Your code goes here...
end

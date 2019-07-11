# frozen_string_literal: true

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

  def self.load(spec_path)
    Definition.new(OasParser::Definition.resolve(spec_path))
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

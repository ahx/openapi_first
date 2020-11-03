# frozen_string_literal: true

require 'yaml'
require 'openapi_first/definition'
require 'openapi_first/version'
require 'openapi_first/inbox'
require 'openapi_first/router'
require 'openapi_first/request_validation'
require 'openapi_first/response_validator'
require 'openapi_first/response_validation'
require 'openapi_first/responder'
require 'openapi_first/app'

module OpenapiFirst
  OPERATION = 'openapi_first.operation'
  PARAMETERS = 'openapi_first.parameters'
  REQUEST_BODY = 'openapi_first.parsed_request_body'
  INBOX = 'openapi_first.inbox'
  HANDLER = 'openapi_first.handler'

  def self.env
    ENV['RACK_ENV'] || ENV['HANAMI_ENV'] || ENV['RAILS_ENV']
  end

  def self.load(spec_path, only: nil)
    Definition.new(spec_path, only: only)
  end

  def self.app(
    spec,
    namespace:,
    router_raise_error: false,
    request_validation_raise_error: false,
    response_validation: false
  )
    spec = OpenapiFirst.load(spec) if spec.is_a?(String)
    App.new(
      nil,
      spec,
      namespace: namespace,
      router_raise_error: router_raise_error,
      request_validation_raise_error: request_validation_raise_error,
      response_validation: response_validation
    )
  end

  def self.middleware(
    spec,
    namespace:,
    router_raise_error: false,
    request_validation_raise_error: false,
    response_validation: false
  )
    spec = OpenapiFirst.load(spec) if spec.is_a?(String)
    AppWithOptions.new(
      spec,
      namespace: namespace,
      router_raise_error: router_raise_error,
      request_validation_raise_error: request_validation_raise_error,
      response_validation: response_validation
    )
  end

  class AppWithOptions
    def initialize(spec, options)
      @spec = spec
      @options = options
    end

    def new(app)
      App.new(app, @spec, **@options)
    end
  end

  class Error < StandardError; end
  class NotFoundError < Error; end
  class NotImplementedError < RuntimeError; end
  class ResponseInvalid < Error; end
  class ResponseCodeNotFoundError < ResponseInvalid; end
  class ResponseContentTypeNotFoundError < ResponseInvalid; end
  class ResponseBodyInvalidError < ResponseInvalid; end

  class RequestInvalidError < Error
    def initialize(serialized_errors)
      message = error_message(serialized_errors)
      super message
    end

    private

    def error_message(errors)
      errors.map do |error|
        [human_source(error), human_error(error)].compact.join(' ')
      end.join(', ')
    end

    def human_source(error)
      return unless error[:source]

      source_key = error[:source].keys.first
      source = {
        pointer: 'Request body invalid:',
        parameter: 'Query parameter invalid:'
      }.fetch(source_key, source_key)
      name = error[:source].values.first
      source += " #{name}" unless name.nil? || name.empty?
      source
    end

    def human_error(error)
      error[:title]
    end
  end
end

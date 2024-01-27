# frozen_string_literal: true

require 'forwardable'
require 'openapi_parameters'
require_relative 'runtime_response'
require_relative 'body_parser'
require_relative 'request_validation/validator'

module OpenapiFirst
  # RuntimeRequest represents how an incoming request (Rack::Request) matches a request definition.
  class RuntimeRequest
    extend Forwardable

    def initialize(request:, path_item:, operation:, path_params:)
      @request = request
      @path_item = path_item
      @operation = operation
      @original_path_params = path_params
      @error = nil
      @validated = false
    end

    def_delegators :@request, :content_type, :media_type, :path
    def_delegators :@operation, :operation_id, :request_method
    def_delegator :@path_item, :path, :path_definition

    attr_reader :path_item, :operation, :error

    def valid?
      validate unless @validated
      error.nil?
    end

    def known?
      known_path? && known_request_method?
    end

    def known_path?
      !!path_item
    end

    def known_request_method?
      !!operation
    end

    # Merged path and query parameters
    def params
      @params ||= query.merge(path_parameters)
    end

    def path_parameters
      return {} unless operation.path_parameters

      @path_parameters ||=
        OpenapiParameters::Path.new(operation.path_parameters).unpack(@original_path_params) || {}
    end

    def query
      return {} unless operation.query_parameters

      @query ||=
        OpenapiParameters::Query.new(operation.query_parameters).unpack(request.env[Rack::QUERY_STRING]) || {}
    end

    alias query_parameters query

    def headers
      return {} unless operation.header_parameters

      @headers ||= OpenapiParameters::Header.new(operation.header_parameters).unpack_env(request.env) || {}
    end

    def cookies
      return {} unless operation.cookie_parameters

      @cookies ||=
        OpenapiParameters::Cookie.new(operation.cookie_parameters).unpack(request.env[Rack::HTTP_COOKIE]) || {}
    end

    def body
      @body ||= BodyParser.new.parse(request, request.media_type)
    end
    alias parsed_body body

    def validate
      @validated = true
      @error = RequestValidation::Validator.new(operation).validate(self)
    end

    def validate!
      error = validate
      error&.raise!
    end

    def validate_response(rack_response, raise_error: false)
      validated = response(rack_response).tap(&:validate)
      validated.error&.raise! if raise_error
      validated
    end

    def response(rack_response)
      RuntimeResponse.new(operation, rack_response)
    end

    private

    attr_reader :request
  end
end

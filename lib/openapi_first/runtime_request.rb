# frozen_string_literal: true

require 'forwardable'
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
    end

    def_delegators :@request, :content_type, :media_type
    def_delegators :@operation, :operation_id

    attr_reader :path_item

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
      @path_parameters ||=
        operation.path_parameters&.unpack(@original_path_params) || {}
    end

    def query
      @query ||=
        operation.query_parameters&.unpack(request.env) || {}
    end

    alias query_parameters query

    def headers
      @headers ||=
        operation.header_parameters&.unpack(request.env) || {}
    end

    def cookies
      @cookies ||=
        operation.cookie_parameters&.unpack(request.env) || {}
    end

    def body
      @body ||= BodyParser.new.parse(request, request.media_type)
    end
    alias parsed_body body

    def validate
      RequestValidation::Validator.new(operation).validate(self)
    end

    def validate!
      error = validate
      error&.raise!
    end

    def response(rack_response)
      RuntimeResponse.new(operation, rack_response)
    end

    private

    attr_reader :request, :operation
  end
end

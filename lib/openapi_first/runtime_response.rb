# frozen_string_literal: true

require 'forwardable'
require_relative 'body_parser'
require_relative 'response_validation/validator'

module OpenapiFirst
  class RuntimeResponse
    extend Forwardable

    def initialize(operation, rack_response)
      @operation = operation
      @rack_response = rack_response
    end

    def_delegators :@rack_response, :status, :content_type
    def_delegators :@operation, :name

    def known?
      !!response_definition
    end

    def known_status?
      @operation.response_status_defined?(status)
    end

    def description
      response_definition&.description
    end

    def body
      @body ||= content_type =~ /json/i ? load_json(original_body) : original_body
    end

    def headers
      @headers ||= unpack_response_headers
    end

    def validate
      ResponseValidation::Validator.new(@operation).validate(self)
    end

    def validate!
      error = validate
      error&.raise!
    end

    def response_definition
      @response_definition ||= @operation.response_for(status, content_type)
    end

    private

    def original_body
      @rack_response.body.join
    end

    def load_json(string)
      MultiJson.load(string)
    rescue MultiJson::ParseError
      raise ParseError, 'Failed to parse response body as JSON'
    end

    def unpack_response_headers
      return {} if response_definition&.headers.nil?

      headers_as_parameters = response_definition.headers.map do |name, definition|
        definition.merge('name' => name, 'in' => 'header')
      end
      OpenapiParameters::Header.new(headers_as_parameters).unpack(@rack_response.header)
    end
  end
end

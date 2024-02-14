# frozen_string_literal: true

require 'forwardable'
require_relative 'body_parser'

module OpenapiFirst
  # Represents a response returned by the Rack application and how it relates to the API description.
  class RuntimeResponse
    extend Forwardable

    def initialize(operation, rack_response, validator:)
      @operation = operation
      @rack_response = rack_response
      @error = nil
      @validator = validator
    end

    # @return [Failure, nil] Error object if validation failed.
    attr_reader :error

    # @attr_reader [Integer] status The HTTP status code of this response.
    # @attr_reader [String] content_type The content_type of the Rack::Response.
    def_delegators :@rack_response, :status, :content_type

    # @return [String] name The name of the operation. Used for generating error messages.
    def name
      "#{@operation.name} response status: #{status}"
    end

    # Checks if the response is valid. Runs the validation unless it has been run before.
    # @return [Boolean]
    def valid?
      validate unless @validated
      @error.nil?
    end

    # Checks if the response is defined in the API description.
    # @return [Boolean] Returns true if the response is known, false otherwise.
    def known?
      !!response_definition
    end

    # Checks if the response status is defined in the API description.
    # @return [Boolean] Returns true if the response status is known, false otherwise.
    def known_status?
      @operation.response_status_defined?(status)
    end

    # Returns the description of the response definition if available.
    # @return [String, nil] Returns the description of the response, or nil if not available.
    def description
      response_definition&.description
    end

    # Returns the parsed (JSON) body of the response.
    # @return [Hash, String] Returns the body of the response.
    def body
      @body ||= content_type =~ /json/i ? load_json(original_body) : original_body
    end

    # Returns the headers of the response as defined in the API description.
    # This only returns the headers that are defined in the API description.
    # @return [Hash] Returns the headers of the response.
    def headers
      @headers ||= unpack_response_headers
    end

    # Validates the response.
    # @return [Failure, nil] Returns the validation error, or nil if the response is valid.
    def validate
      @validated = true
      @error = @validator.call(self)
    end

    # Validates the response and raises an error if invalid.
    # @raise [ResponseNotFoundError, ResponseInvalidError] Raises an error if the response is invalid.
    def validate!
      error = validate
      error&.raise!
    end

    # Returns the response definition associated with the response.
    # @return [Definition::Response, nil] Returns the response definition, or nil if not found.
    def response_definition
      @response_definition ||= @operation.response_for(status, content_type)
    end

    private

    # Usually the body responds to #each, but when using manual response validation without the middleware
    # in Rails request specs the body is a String. So this code handles both cases.
    def original_body
      buffered_body = String.new
      if @rack_response.body.respond_to?(:each)
        @rack_response.body.each { |chunk| buffered_body.to_s << chunk }
        return buffered_body
      end
      @rack_response.body
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
      OpenapiParameters::Header.new(headers_as_parameters).unpack(@rack_response.headers)
    end
  end
end

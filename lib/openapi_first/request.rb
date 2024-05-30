# frozen_string_literal: true

require 'forwardable'
require_relative 'request_parser'
require_relative 'request_validator'
require_relative 'validated_request'

module OpenapiFirst
  # Represents one request definition derived from operation and requestBody definition
  class Request
    extend Forwardable

    def initialize(path:, request_method:, operation_id:, parameters:, content_type:, content_schema:, required_body:,
                   hooks:, openapi_version:)
      @path = path
      @request_method = request_method
      @content_type = content_type
      @content_schema = content_schema
      @required_request_body = required_body == true
      @operation_id = operation_id
      @parameters = build_parameters(parameters)
      @parser = RequestParser.new(
        query_parameters: @parameters[:query],
        path_parameters: @parameters[:path],
        header_parameters: @parameters[:header],
        cookie_parameters: @parameters[:cookie]
      )
      @validator = RequestValidator.new(self, hooks:, openapi_version:)
    end

    attr_reader :content_type, :content_schema, :operation_id, :request_method, :path

    def validate(request, route_params:)
      parsed = @parser.parse(request, route_params:)
      error = @validator.call(parsed)
      ValidatedRequest.new(parsed, error:, request_definition: self)
    end

    # These return a Schema instance for each type of parameters
    %i[path query header cookie].each do |location|
      define_method(:"#{location}_schema") do
        build_parameters_schema(@parameters[location])
      end
    end

    def required_request_body?
      @required_request_body
    end

    private

    IGNORED_HEADERS = Set['Content-Type', 'Accept', 'Authorization'].freeze
    private_constant :IGNORED_HEADERS

    def build_parameters(parameter_definitions)
      result = {}
      parameter_definitions&.each do |parameter|
        (result[parameter['in'].to_sym] ||= []) << parameter
      end
      result[:header]&.reject! { IGNORED_HEADERS.include?(_1['name']) }
      result
    end

    def build_parameters_schema(parameters)
      return unless parameters

      properties = {}
      required = []
      parameters.each do |parameter|
        schema = parameter['schema']
        name = parameter['name']
        properties[name] = schema if schema
        required << name if parameter['required']
      end

      {
        'properties' => properties,
        'required' => required
      }
    end
  end
end

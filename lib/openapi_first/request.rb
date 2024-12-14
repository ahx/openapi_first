# frozen_string_literal: true

require_relative 'request_parser'
require_relative 'request_validator'
require_relative 'validated_request'

module OpenapiFirst
  # Represents one request definition of an OpenAPI description.
  # Note that this is not the same as an OpenAPI 3.x Operation.
  # An 3.x Operation object can accept multiple requests, because it can handle multiple content-types.
  # This class represents one of those requests.
  class Request
    def initialize(path:, request_method:, operation_object:,
                   parameters:, content_type:, content_schema:, required_body:,
                   hooks:, openapi_version:)
      @path = path
      @request_method = request_method
      @content_type = content_type
      @content_schema = content_schema
      @required_request_body = required_body == true
      @operation = operation_object
      @parameters = build_parameters(parameters)
      @request_parser = RequestParser.new(
        query_parameters: @parameters[:query],
        path_parameters: @parameters[:path],
        header_parameters: @parameters[:header],
        cookie_parameters: @parameters[:cookie],
        content_type:
      )
      @validator = RequestValidator.new(self, hooks:, openapi_version:)
    end

    attr_reader :content_type, :content_schema, :operation, :request_method, :path

    def validate(request, route_params:)
      parsed_request = nil
      error = catch FAILURE do
        parsed_request = @request_parser.parse(request, route_params:)
        @validator.call(parsed_request)
        nil
      end
      ValidatedRequest.new(request, parsed_request:, error:, request_definition: self)
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

    def operation_id
      @operation['operationId']
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

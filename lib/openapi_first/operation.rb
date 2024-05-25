# frozen_string_literal: true

require 'forwardable'
require 'openapi_parameters'

module OpenapiFirst
  # Represents an operation object in the OpenAPI 3.X specification.
  # Use this class to access information about the operation. Use `#[key]` to read the raw data.
  # When using the middleware you can access the operation object via `env[OpenapiFirst::REQUEST].operation`.
  class Operation
    extend Forwardable

    def_delegators :operation_object, :[], :dig

    def initialize(path, request_method, operation_object, path_item_parameters:)
      @path = path
      @method = request_method
      @operation_object = operation_object
      @path_item_parameters = path_item_parameters
    end

    # @return [String] path The path of the operation as in the API description.
    attr_reader :path

    # @attr_reader [String] method The (downcased) request method of the operation.
    # Example: "get"
    attr_reader :method
    alias request_method method

    # Returns the operation ID as defined in the API description.
    # @return [String, nil]
    def operation_id
      operation_object['operationId']
    end

    # Returns a unique name for this operation. Used for generating error messages.
    # @visibility private
    def name
      @name ||= "#{method.upcase} #{path}".freeze
    end

    # These return [Hash]
    %i[path query cookie].each do |location|
      define_method(:"#{location}_parameters") do
        all_parameters[location]
      end
    end

    IGNORED_HEADERS = Set['Content-Type', 'Accept', 'Authorization'].freeze
    private_constant :IGNORED_HEADERS

    def header_parameters
      all_parameters[:header]&.reject { IGNORED_HEADERS.include?(_1['name']) }
    end

    # These return a Schema instance for each type of parameters
    %i[path query header cookie].each do |location|
      define_method(:"#{location}_schema") do
        build_parameters_schema(send(:"#{location}_parameters"))
      end
    end

    private

    WRITE_METHODS = Set.new(%w[post put patch delete]).freeze
    private_constant :WRITE_METHODS

    IGNORED_HEADERS = Set['Content-Type', 'Accept', 'Authorization'].freeze
    private_constant :IGNORED_HEADERS

    attr_reader :operation_object

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

    def all_parameters
      @all_parameters ||= begin
        result = {}
        @path_item_parameters&.each do |parameter|
          (result[parameter['in'].to_sym] ||= []) << parameter
        end
        self['parameters']&.each do |parameter|
          (result[parameter['in'].to_sym] ||= []) << parameter
        end
        result
      end
    end
  end
end

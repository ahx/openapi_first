# frozen_string_literal: true

require_relative 'parameter/converter'
require_relative 'parameter/unpackers'

module OpenapiFirst
  # A parameter of a request, or a header of a response.
  class Parameter
    DEFAULT_STYLE = {
      'query' => 'form',
      'path' => 'simple',
      'header' => 'simple',
      'cookie' => 'form'
    }.freeze
    private_constant :DEFAULT_STYLE

    # @param definition [Hash] The OpenAPI Parameter Object. A string keyed Hash.
    # @param schema [Hash, nil] The resolved JSON Schema of this parameter.
    def initialize(definition, schema:)
      @name = definition['name']
      @schema = schema
      @location = definition['in']
      @media_type = definition['content']&.keys&.first
      @style = definition['style'] || DEFAULT_STYLE.fetch(@location)
      @explode = definition.fetch('explode') { @style == 'form' }
      @deep_object = @style == 'deepObject'
      @required = @location == 'path' || definition['required'] == true
      @deprecated = definition['deprecated'] == true
      @converter = Converter[schema]
      @unpacker = Unpackers.find(self)
    end

    attr_reader :name, :schema, :location, :media_type, :style

    def unpack(value)
      return value if value.nil?

      @unpacker.call(value)
    end

    def convert(value) = @converter.call(value)

    # Unpacks and converts a raw value. Values that cannot be unpacked are converted as they are.
    def unpack_and_convert(value)
      convert(catch(:skip) { unpack(value) })
    end

    def explode? = @explode

    def required? = @required

    def deprecated? = @deprecated

    def deep_object? = @deep_object

    def type = schema && schema['type']

    def array? = type == 'array'

    def object? = type == 'object' || deep_object? || schema&.key?('properties')

    # The properties of an object parameter, merged across composition keywords.
    # @return [Hash, nil]
    def object_properties = Converter::ObjectConverter.get_properties(schema)
  end
end

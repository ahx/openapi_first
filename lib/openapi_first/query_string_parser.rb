# frozen_string_literal: true

require 'rack'
require_relative 'parameters_parser'

module OpenapiFirst
  # Unpacks query parameters from a query string.
  # @visibility private
  class QueryStringParser
    DEEP_PROP = '\[([\w-]+)\]$'
    private_constant :DEEP_PROP

    # @param parameters [Array<Parameter>]
    def initialize(parameters)
      @parameters = parameters
      @deep_object_parameters, flat_parameters = parameters.partition(&:deep_object?)
      @flat_parser = ParametersParser.new(flat_parameters)
      @deep_object_properties = {}
      @deep_object_regex = {}
      @deep_object_parameters.each do |parameter|
        @deep_object_properties[parameter.name] = parameter.object_properties
        @deep_object_regex[parameter.name] = /^#{Regexp.escape(parameter.name)}#{DEEP_PROP}/
      end
    end

    attr_reader :parameters

    def unpack(query_string)
      parsed_query = parse_query(query_string)
      result = @flat_parser.unpack(parsed_query)
      @deep_object_parameters.each do |parameter|
        name = parameter.name
        if parsed_query.key?(name)
          result[name] = parameter.convert(parsed_query[name])
        else
          value = parse_deep_object(parameter, parsed_query)
          result[name] = parameter.convert(value) unless value.empty?
        end
      end
      result
    end

    # Returns query parameters that are not defined in the API description
    def unknown_values(query_string)
      parsed_query = parse_query(query_string)
      known_parameter_names = parameters.to_set(&:name)

      unknown = parsed_query.each_with_object({}) do |(key, value), result|
        next if known_parameter_names.include?(key)
        next if @deep_object_parameters.any? { key.start_with?("#{_1.name}[") }

        result[key] = value
      end
      return if unknown.empty?

      unknown
    end

    private

    def parse_query(query_string)
      Rack::Utils.parse_query(query_string) do |string|
        Rack::Utils.unescape(string)
      rescue ArgumentError => e
        raise Rack::Utils::InvalidParameterError, e.message
      end
    end

    def parse_deep_object(parameter, parsed_query)
      name = parameter.name
      prop_regx = @deep_object_regex[name]
      properties_schema = @deep_object_properties[name]

      parsed_query.each.with_object({}) do |(key, value), result|
        prop_key = key.match(prop_regx)&.[](1)
        next if prop_key.nil?

        is_array = properties_schema&.dig(prop_key, 'type') == 'array'
        result[prop_key] = explode_value(value, parameter, is_array)
      end
    end

    def explode_value(value, parameter, is_array)
      value = Array(value)
      if is_array
        return value if parameter.explode?

        return [value.last]
      end
      value.last
    end
  end
end

# frozen_string_literal: true

require 'rack'
require_relative 'object_converter'

module OpenapiFirst
  module Parameters
    # Unpacks query parameters from a query string.
    # @visibility private
    class QueryParser
      DEEP_PROP = '\[([\w-]+)\]$'
      private_constant :DEEP_PROP

      # @param parameters [Array<Parameter>]
      def initialize(parameters)
        @parameters = parameters
        @deep_object_properties = {}
        @deep_object_regex = {}
        parameters.each do |parameter|
          next unless parameter.deep_object?

          @deep_object_properties[parameter.name] = ObjectConverter.get_properties(parameter.schema)
          @deep_object_regex[parameter.name] = /^#{Regexp.escape(parameter.name)}#{DEEP_PROP}/
        end
      end

      attr_reader :parameters

      def unpack(query_string)
        parsed_query = parse_query(query_string)
        parameters.each_with_object({}) do |parameter, result|
          if parameter.deep_object?
            if parsed_query.key?(parameter.name)
              value = parsed_query[parameter.name]
            else
              value = parse_deep_object(parameter, parsed_query)
              next if value.empty?
            end
          else
            next unless parsed_query.key?(parameter.name)

            value = catch(:skip) { parameter.unpack(parsed_query[parameter.name]) }
          end
          result[parameter.name] = parameter.convert(value)
        end
      end

      # Returns query parameters that are not defined in the API description
      def unknown_values(query_string)
        parsed_query = parse_query(query_string)
        known_parameter_names = parameters.to_set(&:name)

        unknown = parsed_query.each_with_object({}) do |(key, value), result|
          next if known_parameter_names.include?(key)
          next if parameters.any? { _1.deep_object? && key.start_with?("#{_1.name}[") }

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
end

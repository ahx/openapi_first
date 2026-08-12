# frozen_string_literal: true

require_relative 'array_converter'
require_relative 'object_converter'

module OpenapiFirst
  module Parameters
    # Converts a parameter value (string) to the type specified in the JSON Schema.
    # @visibility private
    module Converter
      PASS_THROUGH = ->(value) { value }

      INTEGER = lambda do |value|
        Integer(value, 10)
      rescue StandardError
        value
      end

      NUMBER = lambda do |value|
        Float(value)
      rescue StandardError
        value
      end

      BOOLEAN = lambda do |value|
        if value == 'true'
          true
        else
          value == 'false' ? false : value
        end
      end

      class << self
        # Returns a callable that converts a value as described in the schema
        # @param schema [Hash, nil]
        def [](schema)
          case schema && schema['type']
          when 'integer' then INTEGER
          when 'number' then NUMBER
          when 'boolean' then BOOLEAN
          when 'object' then ObjectConverter.new(schema)
          when 'array' then ArrayConverter.new(schema)
          else
            return ObjectConverter.new(schema) if object_like?(schema)

            PASS_THROUGH
          end
        end

        # Converts a nested value, like an array item or an object property
        def convert(value, schema)
          return if value.nil?
          return value if schema.nil?

          self[schema].call(value)
        end

        private

        OBJECT_KEYWORDS = %w[properties oneOf allOf anyOf].freeze
        private_constant :OBJECT_KEYWORDS

        def object_like?(schema)
          schema && OBJECT_KEYWORDS.any? { schema[_1] }
        end
      end
    end
  end
end

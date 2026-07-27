# frozen_string_literal: true

require 'rack'
require_relative 'content_parsers'

module OpenapiFirst
  module Parameters
    # Resolves the unpacker of a parameter once, at Parameter construction time.
    # Each unpacker is a callable that takes a raw string (or already-parsed
    # value) and returns the unpacked Ruby value, throwing :skip on unrecoverable
    # parse errors.
    # @visibility private
    module Unpackers
      ARRAY_DELIMITER = {
        'label' => '.',
        'simple' => ',',
        'form' => ',',
        'pipeDelimited' => '|',
        'spaceDelimited' => ' '
      }.freeze
      private_constant :ARRAY_DELIMITER

      PREFIXED_STYLES = %w[label matrix].freeze
      private_constant :PREFIXED_STYLES

      OBJECT_EXPLODE_SPLITTER = Regexp.union(',', '=').freeze
      private_constant :OBJECT_EXPLODE_SPLITTER

      PassThrough = ->(value) { value }

      DelimitedArray = Data.define(:delimiter, :strip_prefix) do
        def call(value)
          return value if value.is_a?(::Array)
          return value if value.empty?

          value = value[1..] if strip_prefix
          value.split(delimiter)
        end
      end

      MatrixArray = Data.define(:name, :explode) do
        def call(value)
          return value if value.is_a?(::Array)
          return value if value.empty?

          result = Unpackers.parse_query(value, ';')[name]
          return result if explode
          return result unless result.is_a?(::String)

          result.split(',')
        end
      end

      ExplodeFormObject = lambda do |value|
        throw :skip, value unless value.is_a?(::String)

        entries = value.split(OBJECT_EXPLODE_SPLITTER)
        throw :skip, value if entries.length.odd?

        Hash[*entries]
      end

      DelimitedObject = Data.define(:delimiter) do
        def call(value)
          throw :skip, value unless value.is_a?(::String)

          entries = value.split(delimiter)
          throw :skip, value if entries.length.odd?

          Hash[*entries]
        end
      end

      ExplodePathObject = ->(value) { Unpackers.parse_query(value, ',') }

      NonExplodePathObject = Data.define(:array_unpacker) do
        def call(value)
          array = array_unpacker.call(value)
          throw :skip, value if array.length.odd?

          Hash[*array]
        end
      end

      class << self
        # Values that are not encoded as described are left to schema validation
        def parse_query(value, delimiter)
          Rack::Utils.parse_query(value, delimiter)
        rescue ArgumentError
          throw :skip, value
        end

        def find(parameter)
          return find_media_type(parameter) if parameter.media_type
          return find_array(parameter) if parameter.array?
          return find_object(parameter) if parameter.object?

          PassThrough
        end

        private

        def find_media_type(parameter)
          ContentParsers[parameter.media_type] || PassThrough
        end

        def find_array(parameter)
          style = parameter.style
          return MatrixArray.new(name: parameter.name, explode: parameter.explode?) if style == 'matrix'

          DelimitedArray.new(
            delimiter: ARRAY_DELIMITER[style],
            strip_prefix: PREFIXED_STYLES.include?(style)
          )
        end

        def find_object(parameter)
          return find_path_object(parameter) if parameter.location == 'path'
          return ExplodeFormObject if parameter.explode?

          DelimitedObject.new(delimiter: ARRAY_DELIMITER[parameter.style])
        end

        def find_path_object(parameter)
          return ExplodePathObject if parameter.explode?

          NonExplodePathObject.new(array_unpacker: find_array(parameter))
        end
      end
    end
  end
end

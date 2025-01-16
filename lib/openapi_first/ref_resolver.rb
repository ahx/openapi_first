# frozen_string_literal: true

require 'json_schemer'

module OpenapiFirst
  # This is here to give traverse an OAD while keeping $refs intact
  # @visibility private
  module RefResolver
    def self.load(file_path)
      contents = OpenapiFirst::FileLoader.load(file_path)
      self.for(contents, dir: File.dirname(File.expand_path(file_path)))
    end

    def self.for(value, context: value, dir: Dir.pwd)
      case value
      when ::Hash
        Hash.new(value, context:, dir:)
      when ::Array
        Array.new(value, context:, dir:)
      when ::NilClass
        nil
      else
        Simple.new(value)
      end
    end

    # @visibility private
    module Diggable
      def dig(*keys)
        keys.inject(self) do |result, key|
          break unless result.respond_to?(:[])

          result[key]
        end
      end
    end

    # @visibility private
    module Resolvable
      def initialize(value, context: value, dir: nil)
        @value = value
        @context = context
        @dir = (dir && File.absolute_path(dir)) || Dir.pwd
      end

      # The value of this node
      attr_reader :value
      # The path of the file sytem directory where this was loaded from
      attr_reader :dir
      # The object where this node was found in
      attr_reader :context

      def resolve_ref(pointer)
        if pointer.start_with?('#')
          value = Hana::Pointer.new(pointer[1..]).eval(context)
          raise "Unknown reference #{pointer} in #{context}" unless value

          return RefResolver.for(value, dir:)
        end

        relative_path, file_pointer = pointer.split('#')
        full_path = File.expand_path(relative_path, dir)
        return RefResolver.load(full_path) unless file_pointer

        file_contents = FileLoader.load(full_path)
        new_dir = File.dirname(full_path)
        value = Hana::Pointer.new(file_pointer).eval(file_contents)
        RefResolver.for(value, dir: new_dir)
      end
    end

    # @visibility private
    class Simple
      include Resolvable

      def resolved = value
    end

    # @visibility private
    class Hash
      include Resolvable
      include Diggable
      include Enumerable

      def resolved
        return resolve_ref(value['$ref']).value if value.key?('$ref')

        value
      end

      def [](key)
        return resolve_ref(@value['$ref'])[key] if !@value.key?(key) && @value.key?('$ref')

        RefResolver.for(@value[key], dir:, context:)
      end

      def fetch(key)
        return resolve_ref(@value['$ref']).fetch(key) if !@value.key?(key) && @value.key?('$ref')

        RefResolver.for(@value.fetch(key), dir:, context:)
      end

      def each
        resolved.each do |key, value|
          yield key, RefResolver.for(value, dir:, context:)
        end
      end

      def schema(options = {})
        ref_resolver = JSONSchemer::CachedResolver.new do |uri|
          FileLoader.load(uri.path)
        end
        base_uri = URI::File.build({ path: "#{dir}/" })
        root = JSONSchemer::Schema.new(context, base_uri:, ref_resolver:, **options)
        JSONSchemer::Schema.new(value, nil, root, base_uri:, **options)
      end
    end

    # @visibility private
    class Array
      include Resolvable
      include Diggable

      def [](index)
        item = @value[index]
        return resolve_ref(item['$ref']) if item.is_a?(::Hash) && item.key?('$ref')

        RefResolver.for(item, dir:, context:)
      end

      def resolved
        value.map do |item|
          if item.respond_to?(:key?) && item.key?('$ref')
            resolve_ref(item['$ref']).resolved
          else
            item
          end
        end
      end
    end
  end
end

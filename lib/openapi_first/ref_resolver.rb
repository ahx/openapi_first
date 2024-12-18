# frozen_string_literal: true

module OpenapiFirst
  # This is here to give traverse an OAD while keeping $refs intact
  # @visibility private
  module RefResolver
    def self.for(value, context: value, dir: Dir.pwd)
      case value
      when ::Hash
        Hash.new(value, context:, dir:)
      when ::Array
        Array.new(value, context:, dir:)
      else
        Simple.new(value)
      end
    end

    # @visibility private
    module Resolvable
      def initialize(value, context: value, dir: nil)
        @value = value
        @context = context
        @dir = dir
      end

      attr_accessor :value
      private attr_accessor :dir
      private attr_accessor :context

      def resolve_ref(pointer)
        if pointer.start_with?('#')
          value = Hana::Pointer.new(pointer[1..]).eval(context)
          raise "Unknown reference #{pointer} in #{context}" unless value

          return RefResolver.for(value, dir:)
        end

        relative_path, file_pointer = pointer.split('#')
        full_path = File.expand_path(relative_path, dir)
        file_contents = FileLoader.load(full_path)
        new_dir = File.dirname(full_path)
        return RefResolver.for(file_contents, dir: new_dir) unless file_pointer

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
    end

    # @visibility private
    class Array
      include Resolvable

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

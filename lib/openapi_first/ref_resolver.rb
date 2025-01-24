# frozen_string_literal: true

require 'json_schemer'

module OpenapiFirst
  # This is here to give traverse an OAD while keeping $refs intact
  # @visibility private
  module RefResolver
    def self.load(filepath)
      contents = OpenapiFirst::FileLoader.load(filepath)
      self.for(contents, filepath:)
    end

    def self.for(value, filepath: nil, context: value)
      case value
      when ::Hash
        Hash.new(value, context:, filepath:)
      when ::Array
        Array.new(value, context:, filepath:)
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
      def initialize(value, context: value, filepath: nil)
        @value = value
        @context = context
        @filepath = filepath
        dir = File.dirname(File.expand_path(filepath)) if filepath
        @dir = (dir && File.absolute_path(dir)) || Dir.pwd
      end

      # The value of this node
      attr_reader :value
      # The path of the file sytem directory where this was loaded from
      attr_reader :dir
      # The object where this node was found in
      attr_reader :context

      private attr_reader :filepath

      def resolve_ref(pointer)
        if pointer.start_with?('#')
          value = Hana::Pointer.new(pointer[1..]).eval(context)
          raise "Unknown reference #{pointer} in #{context}" unless value

          return RefResolver.for(value, filepath:, context:)
        end

        relative_path, file_pointer = pointer.split('#')
        full_path = File.expand_path(relative_path, dir)
        return RefResolver.load(full_path) unless file_pointer

        file_contents = FileLoader.load(full_path)
        value = Hana::Pointer.new(file_pointer).eval(file_contents)
        RefResolver.for(value, filepath: full_path, context: file_contents)
      rescue OpenapiFirst::FileNotFoundError => e
        message = "Problem with reference resolving #{pointer.inspect} in " \
                  "file #{File.absolute_path(filepath).inspect}: #{e.message}"
        raise OpenapiFirst::FileNotFoundError, message
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

        RefResolver.for(@value[key], filepath:, context:)
      end

      def fetch(key)
        return resolve_ref(@value['$ref']).fetch(key) if !@value.key?(key) && @value.key?('$ref')

        RefResolver.for(@value.fetch(key), filepath:, context:)
      end

      def each
        resolved.each do |key, value|
          yield key, RefResolver.for(value, filepath:, context:)
        end
      end

      # You have to pass configuration or ref_resolver
      def schema(options)
        base_uri = URI::File.build({ path: "#{dir}/" })
        root = JSONSchemer::Schema.new(context, base_uri:, **options)
        JSONSchemer::Schema.new(value, nil, root, base_uri:, **options)
      end
    end

    # @visibility private
    class Array
      include Enumerable
      include Resolvable
      include Diggable

      def [](index)
        item = @value[index]
        return resolve_ref(item['$ref']) if item.is_a?(::Hash) && item.key?('$ref')

        RefResolver.for(item, filepath:, context:)
      end

      def each
        resolved.each do |item|
          yield RefResolver.for(item, filepath:, context:)
        end
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

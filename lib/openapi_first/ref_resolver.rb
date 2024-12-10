# frozen_string_literal: true

module OpenapiFirst
  # This is here to give traverse an OAD while keeping $refs intact
  # @visibility private
  class RefResolver
    include Enumerable

    def initialize(value, context: value, dir: Dir.pwd)
      @value = value
      @context = context
      @dir = dir
    end

    def [](key)
      return resolve_ref(@value['$ref'])[key] if !@value.key?(key) && @value.key?('$ref')

      self.class.new(@value[key], dir:, context:)
    end

    def each
      resolved.each do |key, value|
        yield key, self.class.new(value, dir:)
      end
    end

    def resolved
      if value.is_a?(Hash) && value.key?('$ref')
        return resolve_ref(value['$ref']).value
      elsif value.is_a?(Array)
        return value.map do |item|
          break item.resolved if item.is_a?(self.class)

          item
        end
      end

      value
    end

    attr_accessor :value
    private attr_accessor :dir

    private

    private attr_accessor :context

    def resolve_ref(pointer)
      if pointer.start_with?('#')
        value = Hana::Pointer.new(pointer[1..]).eval(context)
        raise "Unknown reference #{pointer} in #{context}" unless value

        return self.class.new(value, dir:)
      end

      relative_path, file_pointer = pointer.split('#')
      full_path = File.expand_path(relative_path, dir)
      file_contents = FileLoader.load(full_path)
      new_dir = File.dirname(full_path)
      return self.class.new(file_contents, dir: new_dir) unless file_pointer

      value = Hana::Pointer.new(file_pointer).eval(file_contents)
      self.class.new(value, dir: new_dir)
    end
  end
end

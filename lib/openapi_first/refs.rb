# frozen_string_literal: true

module OpenapiFirst
  # Functions to handle $refs
  # @!visibility private
  module Refs
    module_function

    def resolve_file(file_path)
      @files_cache ||= {}
      @files_cache[File.expand_path(file_path)] ||= begin
        data = load_file(file_path)
        resolve_data!(data, context: data, dir: File.dirname(file_path))
      end
    rescue FileNotFoundError => e
      raise e.class, "Problem while loading file referenced in #{file_path}: #{e.message}"
    end

    def load_file(file_path)
      raise FileNotFoundError, "File not found #{file_path}" unless File.exist?(file_path)

      body = File.read(file_path)
      extname = File.extname(file_path)
      return JSON.parse(body) if extname == '.json'
      return YAML.unsafe_load(body) if ['.yaml', '.yml'].include?(extname)

      body
    end

    def resolve_data!(data, context:, dir:)
      case data
      when Hash
        return data if data.key?('discriminator')

        if data.key?('$ref')
          referenced_value = resolve_ref(data.delete('$ref'), context:, dir:)
          data.merge!(referenced_value) if referenced_value.is_a?(Hash)
        end
        data.transform_values! do |value|
          resolve_data!(value, context:, dir:)
        end
      when Array
        data.map! do |value|
          resolve_data!(value, context:, dir:)
        end
      end
      data
    end

    def resolve_ref(pointer, context:, dir:)
      return Hana::Pointer.new(pointer[1..]).eval(context) if pointer.start_with?('#')

      file_path, file_pointer = pointer.split('#')
      file_context = resolve_file(File.expand_path(file_path, dir))
      return file_context unless file_pointer

      data = Hana::Pointer.new(file_pointer).eval(file_context)
      resolve_data!(data, context: file_context, dir: File.dirname(file_path))
    end
  end
end

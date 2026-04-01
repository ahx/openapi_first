# frozen_string_literal: true

require 'json'
require 'yaml'

module OpenapiFirst
  # @!visibility private
  module FileLoader
    @cache = {}
    @mutex = Mutex.new

    module_function

    def load(file_path)
      @cache[file_path] || @mutex.synchronize do
        @cache[file_path] ||= begin
          raise FileNotFoundError, "File not found #{file_path.inspect}" unless File.exist?(file_path)

          body = File.read(file_path)
          extname = File.extname(file_path)

          if extname == '.json'
            ::JSON.parse(body)
          elsif ['.yaml', '.yml'].include?(extname)
            YAML.unsafe_load(body)
          else
            body
          end
        end
      end
    end

    def clear_cache!
      @mutex.synchronize { @cache.clear }
    end
  end
end

# frozen_string_literal: true

require 'hanami/utils/string'

module OpenapiFirst
  module Utils
    def self.underscore(string)
      Hanami::Utils::String.underscore(string)
    end

    def self.classify(string)
      Hanami::Utils::String.classify(string)
    end

    def self.deep_stringify(params) # rubocop:disable Metrics/MethodLength
      params.each_with_object({}) do |(key, value), output|
        output[key.to_s] =
          case value
          when ::Hash
            deep_stringify(value)
          when Array
            value.map do |item|
              item.is_a?(::Hash) ? deep_stringify(item) : item
            end
          else
            value
          end
      end
    end
  end
end

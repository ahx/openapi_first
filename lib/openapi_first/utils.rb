# frozen_string_literal: true

require 'hanami/utils/string'
require 'hanami/utils/hash'
require 'deep_merge/core'

module OpenapiFirst
  module Utils
    def self.deep_merge!(dest, source)
      DeepMerge.deep_merge!(source, dest)
    end

    def self.underscore(string)
      Hanami::Utils::String.underscore(string)
    end

    def self.classify(string)
      Hanami::Utils::String.classify(string)
    end

    class StringKeyedHash
      def initialize(original)
        @orig = original
      end

      def key?(key)
        @orig.key?(key.to_sym)
      end

      def [](key)
        @orig[key.to_sym]
      end
    end
  end
end

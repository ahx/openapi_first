# frozen_string_literal: true

require 'deep_merge/core'

module OpenapiFirst
  module Utils
    def self.deep_merge!(dest, source)
      DeepMerge.deep_merge!(source, dest)
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

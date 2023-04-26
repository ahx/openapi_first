# frozen_string_literal: true

module OpenapiFirst
  module Utils
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

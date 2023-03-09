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
  end
end

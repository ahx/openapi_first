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
  end
end

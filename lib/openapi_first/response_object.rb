# frozen_string_literal: true

require 'forwardable'
require_relative 'utils'

module OpenapiFirst
  # Represents an OpenAPI Response Object
  class ResponseObject
    extend Forwardable
    def_delegators :@parsed,
                   :content

    def_delegators :@raw,
                   :[]

    def initialize(parsed)
      @parsed = parsed
      @raw = parsed.raw
    end
  end
end

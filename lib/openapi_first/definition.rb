# frozen_string_literal: true

require_relative 'operation'

module OpenapiFirst
  class Definition
    attr_reader :filepath

    def initialize(parsed)
      @filepath = parsed.path
      @spec = parsed
    end

    def operations
      @spec.endpoints.map { |e| Operation.new(e) }
    end
  end
end

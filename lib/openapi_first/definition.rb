# frozen_string_literal: true

require_relative 'operation'

module OpenapiFirst
  class Definition
    attr_reader :filepath
    attr_reader :operations

    def initialize(parsed)
      @filepath = parsed.path
      @operations = parsed.endpoints.map { |e| Operation.new(e) }
    end
  end
end

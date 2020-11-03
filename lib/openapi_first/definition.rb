# frozen_string_literal: true

require 'oas_parser'
require_relative 'operation'

module OpenapiFirst
  class Definition
    attr_reader :filepath, :operations

    def initialize(filepath, only: nil)
      @filepath = filepath
      content = YAML.load_file(filepath)
      raw = OasParser::Parser.new(filepath, content).resolve
      parsed = OasParser::Definition.new(raw, filepath)
      @operations = parsed.endpoints.map { |e| Operation.new(e) }
      @operations.filter!(&only) if only
    end
  end
end

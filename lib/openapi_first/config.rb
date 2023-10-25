# frozen_string_literal: true

module OpenapiFirst
  class Config
    def initialize(error_response: :default)
      @error_response = error_response
    end

    attr_reader :error_response

    def self.default_options
      @default_options ||= new
    end

    def self.default_options=(options)
      @default_options = new(**options)
    end
  end
end

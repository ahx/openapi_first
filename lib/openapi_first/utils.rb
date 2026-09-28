# frozen_string_literal: true

module OpenapiFirst
  # @visibility private
  module Utils
    module_function

    def deep_stringify_keys(contents) = ::JSON.parse(::JSON.generate(contents))
  end
end

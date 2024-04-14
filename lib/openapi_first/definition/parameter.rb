# frozen_string_literal: true

require_relative '../schema'

module OpenapiFirst
  class Parameter < OpenapiParameters::Parameter
    def [](key)
      definition[key]
    end
  end
end

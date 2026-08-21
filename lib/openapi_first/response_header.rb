# frozen_string_literal: true

require_relative 'parameter'

module OpenapiFirst
  # A header of a response definition.
  # @attr_reader [Parameter] parameter The header as a Parameter, which knows how to unpack a raw value.
  ResponseHeader = Data.define(:name, :required?, :schema, :parameter)
end

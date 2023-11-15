# frozen_string_literal: true

require 'openapi_parameters'
require_relative 'parameters'

module OpenapiFirst
  class HeaderParameters < Parameters
    def unpack(env)
      OpenapiParameters::Header.new(@parameter_definitions).unpack_env(env)
    end
  end
end

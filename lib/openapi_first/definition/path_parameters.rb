# frozen_string_literal: true

require 'openapi_parameters'
require_relative 'parameters'
require_relative '../router'

module OpenapiFirst
  class PathParameters < Parameters
    def unpack(env)
      OpenapiParameters::Path.new(@parameter_definitions).unpack(env[Router::RAW_PATH_PARAMS])
    end
  end
end

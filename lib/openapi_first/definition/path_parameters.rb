# frozen_string_literal: true

require 'openapi_parameters'
require_relative 'parameters'
require_relative '../router'

module OpenapiFirst
  class PathParameters < Parameters
    def unpack(original_path_params)
      OpenapiParameters::Path.new(@parameter_definitions).unpack(original_path_params)
    end
  end
end

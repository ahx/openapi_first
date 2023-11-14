# frozen_string_literal: true

require 'openapi_parameters'
require_relative 'parameters'

module OpenapiFirst
  class QueryParameters < Parameters
    def unpack(env)
      OpenapiParameters::Query.new(@parameter_definitions).unpack(env['QUERY_STRING'])
    end
  end
end

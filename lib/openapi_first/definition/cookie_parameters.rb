# frozen_string_literal: true

require 'openapi_parameters'
require_relative 'parameters'

module OpenapiFirst
  class CookieParameters < Parameters
    def unpack(env)
      OpenapiParameters::Cookie.new(@parameter_definitions).unpack(env['HTTP_COOKIE'])
    end
  end
end

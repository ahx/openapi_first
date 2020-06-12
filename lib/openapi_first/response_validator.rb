# frozen_string_literal: true

require 'json_schemer'
require 'multi_json'
require_relative 'validation'
require_relative 'router'

module OpenapiFirst
  class ResponseValidator
    def initialize(spec)
      @spec = spec
      @router = Router.new(->(_env) {}, spec: spec, raise_error: true)
      @response_validation = ResponseValidation.new(->(response) { response.to_a })
    end

    def validate(request, response)
      env = request.env.dup
      @router.call(env)
      @response_validation.validate(response, env[OPERATION])
    end
  end
end

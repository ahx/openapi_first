# frozen_string_literal: true

require 'multi_json'
require_relative 'use_router'
require_relative 'response_validation/validator'

module OpenapiFirst
  class ResponseInvalid < StandardError; end
  class ResponseCodeNotFoundError < ResponseInvalid; end
  class ResponseContentTypeNotFoundError < ResponseInvalid; end
  class ResponseHeaderInvalidError < ResponseInvalid; end
  class ResponseBodyInvalidError < ResponseInvalid; end

  class ResponseValidation
    prepend UseRouter

    def initialize(app, _options = {})
      @app = app
    end

    def call(env)
      operation = env[OPERATION]
      return @app.call(env) unless operation

      response = @app.call(env)
      Validator.new(operation).validate(response)
      response
    end
  end
end

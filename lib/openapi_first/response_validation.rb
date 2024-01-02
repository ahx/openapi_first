# frozen_string_literal: true

require 'multi_json'
require_relative 'response_validation/middleware'

module OpenapiFirst
  class ResponseInvalid < StandardError; end
  class ResponseCodeNotFoundError < ResponseInvalid; end
  class ResponseContentTypeNotFoundError < ResponseInvalid; end
  class ResponseHeaderInvalidError < ResponseInvalid; end
  class ResponseBodyInvalidError < ResponseInvalid; end

  module ResponseValidation
    def self.new(app, options = {})
      Middleware.new(app, options)
    end
  end
end

# frozen_string_literal: true

require 'multi_json'
require_relative 'response_validation/middleware'

module OpenapiFirst
  module ResponseValidation
    def self.new(app, options = {})
      Middleware.new(app, options)
    end
  end
end

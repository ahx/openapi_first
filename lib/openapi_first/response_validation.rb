# frozen_string_literal: true

require 'multi_json'
require_relative 'middlewares/response_validation'

module OpenapiFirst
  module ResponseValidation
    def self.new(app, options = {})
      OpenapiFirst::Middlewares::ResponseValidation.new(app, options)
    end
  end
end

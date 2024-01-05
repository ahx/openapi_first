# frozen_string_literal: true

require_relative 'middlewares/request_validation'

module OpenapiFirst
  module RequestValidation
    def self.new(app, options = {})
      OpenapiFirst::Middlewares::RequestValidation.new(app, options)
    end
  end
end

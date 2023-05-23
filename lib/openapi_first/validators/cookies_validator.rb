# frozen_string_literal: true

require_relative './parameters_validator'

module OpenapiFirst
  module Validators
    class CookiesValidator < ParametersValidator
      def source_name
        :cookie
      end
    end
  end
end

# frozen_string_literal: true

require_relative './parameters_validator'

module OpenapiFirst
  module Validators
    class HeadersValidator < ParametersValidator
      def source_name
        :header
      end
    end
  end
end

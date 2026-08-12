# frozen_string_literal: true

module OpenapiFirst
  module Validators
    class RequiredRequestBody
      def call(parsed_request)
        Failure.new(:invalid_body, message: 'Request body must not be empty') if parsed_request.body.nil?
      end
    end
  end
end

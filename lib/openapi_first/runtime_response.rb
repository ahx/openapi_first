# frozen_string_literal: true

require_relative 'response_validation/validator'

module OpenapiFirst
  class RuntimeResponse
    def initialize(operation, rack_response)
      @operation = operation
      @rack_response = rack_response
    end

    def description
      response_definition&.description
    end

    def validate
      ResponseValidation::Validator.new(@operation).validate(@rack_response)
    end

    def validate!
      error = validate
      error&.raise!
    end

    private

    def response_definition
      @response_definition ||= @operation.response_for(@rack_response.status, @rack_response.content_type)
    end
  end
end

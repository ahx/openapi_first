# frozen_string_literal: true

module OpenapiFirst
  # This is the base class for error responses
  class ErrorResponse
    ## @param request_validation_error [OpenapiFirst::RequestValidationError]
    def initialize(request_validation_error)
      @request_validation_error = request_validation_error
    end

    extend Forwardable

    attr_reader :request_validation_error

    def_delegators :@request_validation_error, :status, :location, :schema_validation

    def validation_output
      schema_validation&.output
    end

    def schema
      schema_validation&.schema
    end

    def data
      schema_validation&.data
    end

    def message
      request_validation_error.message
    end

    def render
      Rack::Response.new(body, status, Rack::CONTENT_TYPE => content_type).finish
    end

    def content_type = 'application/json'

    def body
      raise NotImplementedError
    end
  end
end

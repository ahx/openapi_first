# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  # This is the base class for error responses
  class ErrorResponse
    ## @param request [Hash] The Rack request env
    ## @param failure [OpenapiFirst::RequestValidation::Failure]
    def initialize(failure: nil)
      @failure = failure
    end

    extend Forwardable

    def_delegators :@failure, :error_type, :request, :validation_result

    STATUS = {
      not_found: 404,
      method_not_allowed: 405,
      unsupported_media_type: 415
    }.freeze
    private_constant :STATUS

    def status
      STATUS[error_type] || 400
    end

    def message
      Rack::Utils::HTTP_STATUS_CODES[status]
    end

    def validation_output
      validation_result&.output
    end

    def schema
      validation_result&.schema
    end

    def data
      validation_result&.data
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

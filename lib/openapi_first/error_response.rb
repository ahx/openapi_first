# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  # This is the base class for error responses
  class ErrorResponse
    ## @param request [Hash] The Rack request env
    ## @param failure [OpenapiFirst::RequestValidation::Failure]
    def initialize(env, failure = nil)
      @env = env
      @failure = failure
    end

    extend Forwardable

    attr_reader :env

    def_delegators :@failure, :status, :location, :message, :request, :schema_validation

    def validation_output
      schema_validation&.output
    end

    def schema
      schema_validation&.schema
    end

    def data
      schema_validation&.data
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

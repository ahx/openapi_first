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

    def_delegators :@failure, :status, :location, :message, :request, :validation_result

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

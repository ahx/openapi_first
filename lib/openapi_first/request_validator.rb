# frozen_string_literal: true

require_relative 'failure'
require_relative 'validators/request_parameters'
require_relative 'validators/request_body'

module OpenapiFirst
  # Validates a Request against a request definition.
  class RequestValidator
    def initialize(request_definition, openapi_version:, hooks: {})
      @validators = []
      @validators << Validators::RequestBody.new(request_definition) if request_definition.content_schema
      @validators.concat Validators::RequestParameters.for(request_definition, openapi_version:, hooks:)
    end

    def call(parsed_request)
      @validators.each { |v| v.call(parsed_request) }
    end
  end
end

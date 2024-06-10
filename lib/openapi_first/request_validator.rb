# frozen_string_literal: true

require_relative 'failure'
require_relative 'validators/request_parameters'
require_relative 'validators/request_body'

module OpenapiFirst
  # Validates a Request against a request definition.
  class RequestValidator
    VALIDATORS = [
      Validators::RequestParameters,
      Validators::RequestBody
    ].freeze

    def initialize(request_definition, openapi_version:, hooks: {})
      @validators = VALIDATORS.filter_map do |klass|
        klass.for(request_definition, hooks:, openapi_version:)
      end
    end

    def call(parsed_request)
      @validators.each { |v| v.call(parsed_request) }
    end
  end
end

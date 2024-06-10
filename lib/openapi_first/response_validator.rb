# frozen_string_literal: true

require_relative 'validators/response_headers'
require_relative 'validators/response_body'

module OpenapiFirst
  # Entry point for response validators
  class ResponseValidator
    VALIDATORS = [
      Validators::ResponseHeaders,
      Validators::ResponseBody
    ].freeze

    def initialize(response_definition, openapi_version:)
      @validators = VALIDATORS.filter_map do |klass|
        klass.for(response_definition, openapi_version:)
      end
    end

    def call(parsed_response)
      catch FAILURE do
        @validators.each { |v| v.call(parsed_response) }
        nil
      end
    end
  end
end

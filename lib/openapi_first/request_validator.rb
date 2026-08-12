# frozen_string_literal: true

require_relative 'failure'
require_relative 'validators/request_parameters'
require_relative 'validators/request_body'

module OpenapiFirst
  # Validates a Request against a request definition.
  class RequestValidator
    def initialize(
      content_schema:,
      content_type:,
      required_request_body:,
      path_schema:,
      query_schema:,
      header_schema:,
      cookie_schema:
    )
      @validators = []
      if content_schema
        @validators.concat Validators::RequestBody.for(content_schema:, required_request_body:, content_type:)
      end
      @validators.concat Validators::RequestParameters.for(
        path_schema:,
        query_schema:,
        header_schema:,
        cookie_schema:
      )
    end

    def call(parsed_request)
      @validators.each do |v|
        result = v.call(parsed_request)
        return result if result.is_a?(Failure)
      end
      nil
    end
  end
end

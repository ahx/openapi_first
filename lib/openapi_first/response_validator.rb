require 'json_schemer'
require_relative 'validation'

module OpenapiFirst
  class ResponseValidator
    def initialize(schema)
      @schema = schema
    end

    def validate(request, response)
      response_schema = @schema
        .path_by_path(request.path)
        .endpoint_by_method(request.request_method.downcase)
        .response_by_code(response.status.to_s)
        .content[response.content_type]&.[]('schema')
      return false unless response_schema

      response_data = JSON.parse(response.body)
      Validation.new(JSONSchemer.schema(response_schema).validate(response_data))
    end
  end
end

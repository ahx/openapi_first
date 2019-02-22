require 'json_schemer'

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
        .content[response.content_type]['schema']

      response_data = JSON.parse(response.body)
      JSONSchemer.schema(response_schema).valid?(response_data)
    end
  end
end

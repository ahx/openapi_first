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
        .content[response.content_type]&.[]('schema')
      return false unless response_schema

      response_data = JSON.parse(response.body)
      Validation.new(JSONSchemer.schema(response_schema).validate(response_data))
    end

    class Validation
      attr_reader :errors

      def initialize(errors)
        @errors = errors.to_a.each { |error| error.delete('root_schema') }
      end
    end
  end
end

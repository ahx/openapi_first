# frozen_string_literal: true

module OpenapiFirst
  module MiddlewareHelpers
    def validate_json_schema(schema, object)
      JSONSchemer.schema(schema).validate(object)
    end

    def default_error(status, title = Rack::Utils::HTTP_STATUS_CODES[status])
      {
        status: status.to_s,
        title: title
      }
    end

    def error_response(status, errors = [default_error(status)])
      Rack::Response.new(
        MultiJson.dump(errors: errors),
        status,
        Rack::CONTENT_TYPE => JSON_API_CONTENT_TYPE
      )
    end
  end
end

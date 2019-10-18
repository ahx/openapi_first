# frozen_string_literal: true

require 'rack'
require 'json_schemer'
require 'multi_json'
require_relative 'validation_format'
require_relative 'error_response_method'
require_relative 'query_parameters'

module OpenapiFirst
  class QueryParameterValidation
    include ErrorResponseMethod

    def initialize(app, allow_additional_parameters: false)
      @app = app
      @additional_properties = allow_additional_parameters
    end

    def call(env)
      req = Rack::Request.new(env)
      operation = env[OpenapiFirst::OPERATION]
      schemas = QueryParameters.new(
        allow_additional_parameters: allow_additional_parameters
      )
      schema = operation && schemas.find(operation)
      if schema
        params = req.params
        errors = schema && JSONSchemer.schema(schema).validate(params)
        return error_response(400, serialize_errors(errors)) if errors&.any?

        req.env[QUERY_PARAMS] = allowed_query_parameters(schema, params)
      end

      @app.call(env)
    end

    def allowed_query_parameters(params_schema, query_params)
      params_schema['properties']
        .keys
        .each_with_object({}) do |parameter_name, filtered|
          value = query_params[parameter_name]
          filtered[parameter_name] = value if value
        end
    end

    def serialize_errors(validation_errors)
      validation_errors.map do |error|
        {
          source: {
            parameter: File.basename(error['data_pointer'])
          }
        }.update(ValidationFormat.error_details(error))
      end
    end
  end
end

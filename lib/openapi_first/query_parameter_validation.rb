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
      params = Rack::Request.new(env).params
      json_schema = QueryParameters.new(
        operation: env[OpenapiFirst::OPERATION],
        allow_additional_parameters: @additional_properties
      ).to_json_schema

      catch(:halt) do
        validate_query_parameters!(json_schema, params)
        env[QUERY_PARAMS] = allowed_params(json_schema, params) if json_schema
        @app.call(env)
      end
    end

    private

    def validate_query_parameters!(json_schema, params)
      return unless json_schema

      errors = JSONSchemer.schema(json_schema).validate(params)
      halt error_response(400, serialize_errors(errors)) if errors&.any?
    end

    def halt(response)
      throw :halt, response
    end

    def allowed_params(json_schema, params)
      json_schema['properties']
        .keys
        .each_with_object({}) do |parameter_name, filtered|
          next unless params.key?(parameter_name)

          filtered[parameter_name] = params[parameter_name]
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

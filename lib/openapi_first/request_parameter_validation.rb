# frozen_string_literal: true

require 'rack'
require 'json_schemer'
require 'multi_json'

module OpenapiFirst
  class RequestParameterValidation
    JSON_API_CONTENT_TYPE = 'application/vnd.api+json'

    def initialize(app, spec:)
      @app = app
      @spec = spec
    end

    def call(env)
      req = Rack::Request.new(env)
      schema = parameter_schema(req)
      errors = schema && JSONSchemer.schema(schema).validate(req.params)
      return error_response(errors) if errors&.any?

      @app.call(env)
    end

    def error_response(validation_errors)
      Rack::Response.new(
        MultiJson.dump(errors: serialize_errors(validation_errors.to_a)),
        400,
        Rack::CONTENT_TYPE => JSON_API_CONTENT_TYPE
      )
    end

    def parameter_schema(req)
      spec_parameters(req).each_with_object(
        'type' => 'object',
        'required' => [],
        'additionalProperties' => false,
        'properties' => {}
      ) do |parameter, schema|
        schema['required'] << parameter.name if parameter.required
        schema['properties'][parameter.name] = parameter.schema
      end
    rescue OasParser::PathNotFound, OasParser::MethodNotFound
      nil
    end

    def serialize_errors(validation_errors)
      validation_errors.each_with_object([]) do |error, errors|
        if error['type'] == 'pattern'
          errors << {
            title: 'is not valid',
            detail: "does not match pattern '#{error['schema']['pattern']}'",
            source: {
              parameter: File.basename(error['data_pointer'])
            }
          }
        elsif error['type'] == 'required'
          error['details']['missing_keys'].each do |parameter|
            errors << {
              title: 'is missing',
              source: {
                parameter: parameter
              }
            }
          end
        else
          errors << {
            title: 'is not valid',
            source: {
              parameter: File.basename(error['data_pointer'])
            }
          }
        end
      end
    end

    def spec_parameters(req)
      @spec
        .path_by_path(req.path)
        .endpoint_by_method(req.request_method.downcase)
        .query_parameters
    end
  end
end
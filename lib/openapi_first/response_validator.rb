# frozen_string_literal: true

require 'json_schemer'
require 'multi_json'
require_relative 'validation'

module OpenapiFirst
  class ResponseValidator
    def initialize(schema)
      @schema = schema
    end

    def validate(request, response)
      errors = validation_errors(request, response)
      Validation.new(errors || [])
    rescue OasParser::ResponseCodeNotFound, OasParser::MethodNotFound => e
      Validation.new([e.message])
    end

    private

    def validation_errors(request, response)
      content = response_for(request, response).content
      return unless content

      content_type = content[response.content_type]
      unless content_type
        return ["Content type not found: '#{response.content_type}'"]
      end

      response_schema = content_type['schema']
      return unless response_schema

      response_data = MultiJson.load(response.body)
      validate_json_schema(response_schema, response_data)
    end

    def validate_json_schema(schema, data)
      JSONSchemer.schema(schema).validate(data).to_a.map do |error|
        error.delete('root_schema')
        error
      end
    end

    def response_for(request, response)
      @schema
        .path_by_path(request.path)
        .endpoint_by_method(request.request_method.downcase)
        .response_by_code(response.status.to_s, use_default: true)
    end
  end
end

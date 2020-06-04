# frozen_string_literal: true

require 'json_schemer'
require 'multi_json'
require_relative 'validation'
require_relative 'router'

module OpenapiFirst
  class ResponseValidator
    def initialize(spec)
      @spec = spec
      @router = Router.new(->(_env) {}, spec: spec, raise: true)
    end

    def validate(request, response)
      errors = validation_errors(request, response)
      Validation.new(errors || [])
    rescue OpenapiFirst::ResponseCodeNotFoundError, OpenapiFirst::NotFoundError => e
      Validation.new([e.message])
    end

    def validate_operation(request, response)
      errors = validation_errors(request, response)
      Validation.new(errors || [])
    rescue OpenapiFirst::ResponseCodeNotFoundError, OpenapiFirst::NotFoundError => e
      Validation.new([e.message])
    end

    private

    def validation_errors(request, response)
      content = response_for(request, response)&.fetch('content', nil)
      return unless content

      content_type = content[response.content_type]
      return ["Content type not found: '#{response.content_type}'"] unless content_type

      response_schema = content_type['schema']
      return unless response_schema

      response_data = MultiJson.load(response.body)
      validate_json_schema(response_schema, response_data)
    end

    def validate_json_schema(schema, data)
      JSONSchemer.schema(schema).validate(data).to_a.map do |error|
        format_error(error)
      end
    end

    def format_error(error)
      ValidationFormat.error_details(error)
                      .merge!(
                        data_pointer: error['data_pointer'],
                        schema_pointer: error['schema_pointer']
                      )
    end

    def response_for(request, response)
      env = request.env.dup
      @router.call(env)
      operation = env[OPERATION]
      operation&.response_for(response.status)
    end
  end
end

# frozen_string_literal: true

require 'json_schemer'
require 'multi_json'
require_relative 'validation'

module OpenapiFirst
  class ResponseValidation
    def initialize(app)
      @app = app
    end

    def call(env)
      operation = env[OPERATION]
      return @app.call(env) unless operation

      status, headers, body = @app.call(env)
      content_type = headers[Rack::CONTENT_TYPE]
      response_schema = operation.response_schema_for(status, content_type)
      validate_response_body(response_schema, body) if response_schema

      [status, headers, body]
    end

    private

    def halt(status, body = '')
      throw :halt, [status, {}, body]
    end

    def error(message)
      { title: message }
    end

    def error_response(status, errors)
      Rack::Response.new(
        MultiJson.dump(errors: errors),
        status,
        Rack::CONTENT_TYPE => 'application/vnd.api+json'
      ).finish
    end

    def validate_response_body(schema, response)
      full_body = +''
      response.each { |chunk| full_body << chunk }
      data = full_body.empty? ? {} : MultiJson.load(full_body)
      errors = JSONSchemer.schema(schema).validate(data).to_a.map do |error|
        format_error(error)
      end
      raise ResponseBodyInvalidError, errors.join(', ') if errors.any?
    end

    def format_error(error)
      err = ValidationFormat.error_details(error)
      [err[:title], 'at', error['data_pointer'], err[:detail]].compact.join(' ')
    end
  end
end

# frozen_string_literal: true

require 'json_schemer'
require 'multi_json'
require_relative 'validation'

module OpenapiFirst
  class ResponseValidator
    def initialize(spec)
      @spec = spec
    end

    def validate(request, response)
      errors = validation_errors(request, response)
      Validation.new(errors || [])
    rescue OasParser::ResponseCodeNotFound, OasParser::MethodNotFound => e
      Validation.new([e.message])
    end

    private

    def validation_errors(request, response)
      content = response_for(request, response)&.content
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
        format_error(error)
      end
    end

    def format_error(error)
      ValidationFormat.error_details(error)
                      .merge!(
                        data_pointer: error['data_pointer'],
                        schema_pointer: error['schema_pointer']
                      ).tap do |formatted|
      end
    end

    def response_for(request, response)
      @spec
        .find_operation!(request)
        &.response_by_code(response.status.to_s, use_default: true)
    end
  end
end

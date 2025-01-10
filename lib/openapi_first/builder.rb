# frozen_string_literal: true

require_relative 'json_pointer'
require_relative 'ref_resolver'

module OpenapiFirst
  # Builds parts of a Definition
  # This knows how to read a resolved OpenAPI document and build {Request} and {Response} objects.
  class Builder
    REQUEST_METHODS = %w[get head post put patch delete trace options].freeze

    # Builds a router from a resolved OpenAPI document.
    # @param contents [Hash] The OpenAPI document Hash.
    # @param config [OpenapiFirst::Configuration] The configuration object.
    def self.build_router(contents, filepath:, config:)
      new(contents, filepath:, config:).router
    end

    def initialize(contents, filepath:, config:)
      @schemer_configuration = JSONSchemer::Configuration.new(
        meta_schema: detect_meta_schema(contents, filepath),
        insert_property_defaults: true
      )
      @config = config
      @openapi_version = (contents['openapi'] || contents['swagger'])[0..2]
      @contents = RefResolver.for(contents, dir: filepath && File.dirname(filepath))
    end

    attr_reader :openapi_version, :config
    private attr_reader :schemer_configuration, :schemer_

    def detect_meta_schema(document, filepath)
      # Copied from JSONSchemer 🙇🏻‍♂️
      version = document['openapi']
      case version
      when /\A3\.1\.\d+\z/
        @document_schema = JSONSchemer.openapi31_document
        document.fetch('jsonSchemaDialect') { JSONSchemer::OpenAPI31::BASE_URI.to_s }
      when /\A3\.0\.\d+\z/
        @document_schema = JSONSchemer.openapi30_document
        JSONSchemer::OpenAPI30::BASE_URI.to_s
      else
        raise Error, "Unsupported OpenAPI version #{version.inspect} #{filepath}"
      end
    end

    def router # rubocop:disable Metrics/MethodLength
      router = OpenapiFirst::Router.new
      @contents.fetch('paths').each do |path, path_item_object|
        path_item_object.resolved.keys.intersection(REQUEST_METHODS).map do |request_method|
          operation_object = path_item_object[request_method]
          parameters = operation_object['parameters']&.resolved.to_a.chain(path_item_object['parameters']&.resolved.to_a)
          build_requests(path:, request_method:, operation_object:,
                         parameters:).each do |request|
            router.add_request(
              request,
              request_method:,
              path:,
              content_type: request.content_type
            )
          end
          build_responses(responses: operation_object['responses']).each do |response|
            router.add_response(
              response,
              request_method:,
              path:,
              status: response.status,
              response_content_type: response.content_type
            )
          end
        end
      end
      router
    end

    def build_requests(path:, request_method:, operation_object:, parameters:)
      required_body = operation_object['requestBody']&.resolved&.fetch('required', false) == true
      result = operation_object.dig('requestBody', 'content')&.map do |content_type, content_object|
        content_schema = content_object['schema'].schema(
          configuration: schemer_configuration,
          after_property_validation: config.hooks[:after_request_body_property_validation]
        )
        Request.new(path:, request_method:,
                    operation_object: operation_object.resolved,
                    parameters:, content_type:,
                    content_schema:,
                    required_body:, hooks: config.hooks, openapi_version:)
      end || []
      return result if required_body

      result << Request.new(
        path:, request_method:, operation_object: operation_object.resolved,
        parameters:, content_type: nil, content_schema: nil,
        required_body:, hooks: config.hooks, openapi_version:
      )
    end

    def build_responses(responses:)
      return [] unless responses

      responses.flat_map do |status, response_object|
        headers = response_object['headers']&.resolved
        response_object['content']&.map do |content_type, content_object|
          content_schema = content_object['schema'].schema(configuration: schemer_configuration)
          Response.new(status:,
                       headers:,
                       content_type:,
                       content_schema:,
                       openapi_version:)
        end || Response.new(status:, headers:, content_type: nil,
                            content_schema: nil, openapi_version:)
      end
    end
  end
end

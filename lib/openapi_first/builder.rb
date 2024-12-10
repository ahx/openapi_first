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
      ref_resolver = JSONSchemer::CachedResolver.new do |uri|
        FileLoader.load(File.join(File.dirname(filepath), uri.path))
      end
      configuration = JSONSchemer::Configuration.new(
        ref_resolver:,
        insert_property_defaults: true,
        after_property_validation: config.hooks[:after_request_body_property_validation]
      )
      @doc = JSONSchemer.openapi(contents, configuration:)
      @config = config
      @openapi_version = (contents['openapi'] || contents['swagger'])[0..2]
      @contents = contents
    end

    attr_reader :openapi_version, :config

    def router # rubocop:disable Metrics/MethodLength
      router = OpenapiFirst::Router.new
      RefResolver.new(@contents)['paths'].each do |path, path_item_object|
        path_item_object.resolved.keys.intersection(REQUEST_METHODS).map do |request_method|
          operation_object = path_item_object[request_method]
          operation_pointer = JsonPointer.append('#', 'paths', URI::DEFAULT_PARSER.escape(path), request_method)
          build_requests(path:, request_method:, operation_object:, operation_pointer:,
                         path_item_object:).each do |request|
            router.add_request(
              request,
              request_method:,
              path:,
              content_type: request.content_type
            )
          end
          build_responses(operation_pointer:, operation_object: operation_object.resolved).each do |response|
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

    def build_requests(path:, request_method:, operation_object:, operation_pointer:, path_item_object:)
      hooks = config.hooks
      parameters = operation_object['parameters'].resolved.to_a.chain(path_item_object['parameters'].resolved.to_a)
      required_body = operation_object['requestBody'].resolved&.fetch('required', nil) == true
      result = operation_object['requestBody'].resolved&.fetch('content', nil)&.map do |content_type, _content|
        content_schema = @doc.ref(JsonPointer.append(operation_pointer, 'requestBody', 'content', content_type,
                                                     'schema'))
        Request.new(path:, request_method:, operation_object: operation_object.resolved, parameters:, content_type:,
                    content_schema:, required_body:, hooks:, openapi_version:)
      end || []
      return result if required_body

      result << Request.new(
        path:, request_method:, operation_object: operation_object.resolved,
        parameters:, content_type: nil, content_schema: nil,
        required_body:, hooks:, openapi_version:
      )
    end

    def build_responses(operation_pointer:, operation_object:)
      Array(operation_object['responses']).flat_map do |status, response_object|
        headers = response_object['headers']
        response_object['content']&.map do |content_type, content_object|
          content_schema = if content_object['schema']
                             @doc.ref(JsonPointer.append(operation_pointer, 'responses', status, 'content', content_type,
                                                         'schema'))
                           end
          Response.new(status:, headers:, content_type:, content_schema:, openapi_version:)
        end || Response.new(status:, headers:, content_type: nil,
                            content_schema: nil, openapi_version:)
      end
    end
  end
end

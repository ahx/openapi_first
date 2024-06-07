# frozen_string_literal: true

module OpenapiFirst
  # Builds parts of a Definition
  # This knows how to read a resolved OpenAPI document and build {Request} and {Response} objects.
  class Builder
    REQUEST_METHODS = %w[get head post put patch delete trace options].freeze

    # Builds a router from a resolved OpenAPI document.
    # @param resolved [Hash] The resolved OpenAPI document.
    # @param config [OpenapiFirst::Configuration] The configuration object.
    def self.build_router(resolved, config)
      openapi_version = (resolved['openapi'] || resolved['swagger'])[0..2]
      new(resolved, config, openapi_version).router
    end

    def initialize(resolved, config, openapi_version)
      @resolved = resolved
      @config = config
      @openapi_version = openapi_version
    end

    attr_reader :resolved, :openapi_version, :config

    def router # rubocop:disable Metrics/MethodLength
      router = OpenapiFirst::Router.new
      resolved['paths'].each do |path, path_item_object|
        path_item_object.slice(*REQUEST_METHODS).keys.map do |request_method|
          operation_object = path_item_object[request_method]
          build_requests(path, request_method, operation_object, path_item_object).each do |request|
            router.add_request(
              request,
              request_method:,
              path:,
              content_type: request.content_type
            )
          end
          build_responses(operation_object).each do |response|
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

    def build_requests(path, request_method, operation_object, path_item_object)
      hooks = config.hooks
      path_item_parameters = path_item_object['parameters']
      parameters = operation_object['parameters'].to_a.chain(path_item_parameters.to_a)
      required_body = operation_object.dig('requestBody', 'required') == true
      result = operation_object.dig('requestBody', 'content')&.map do |content_type, content|
        Request.new(path:, request_method:, operation_object:, parameters:, content_type:,
                    content_schema: content['schema'], required_body:, hooks:, openapi_version:)
      end || []
      return result if required_body

      result << Request.new(
        path:, request_method:, operation_object:,
        parameters:, content_type: nil, content_schema: nil,
        required_body:, hooks:, openapi_version:
      )
    end

    def build_responses(operation_object)
      Array(operation_object['responses']).flat_map do |status, response_object|
        headers = response_object['headers']
        response_object['content']&.map do |content_type, content_object|
          content_schema = content_object['schema']
          Response.new(status:, headers:, content_type:, content_schema:, openapi_version:)
        end || Response.new(status:, headers:, content_type: nil,
                            content_schema: nil, openapi_version:)
      end
    end
  end
end

# frozen_string_literal: true

require_relative 'openapi3/builder'

module OpenapiFirst
  # Builds parts of a Doc
  module Builder
    BUILDERS = {
      '3.0' => OpenapiFirst::Openapi3::Builder,
      '3.1' => OpenapiFirst::Openapi3::Builder
    }.freeze

    def self.build_router(resolved, config)
      openapi_version = (resolved['openapi'] || resolved['swagger'])[0..2]
      klass = BUILDERS.fetch(openapi_version) do
        raise "Unsupported OpenAPI version: #{openapi_version}"
      end
      klass.new(resolved, config, openapi_version).router
    end
  end
end

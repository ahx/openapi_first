# frozen_string_literal: true

module OpenapiFirst
  class MediaType
    def initialize(media_type_object, operation)
      @media_type_object = media_type_object
      @operation = operation
    end

    def schema
      schema_object = @media_type_object['schema']
      return unless schema_object

      JsonSchema.new(schema_object, write: @operation.write?, openapi_version: @operation.openapi_version)
    end
  end
end

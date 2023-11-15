# frozen_string_literal: true

module OpenapiFirst
  class MediaType
    def initialize(media_type_object, operation)
      @media_type_object = media_type_object
      @operation = operation

      schema_object = @media_type_object['schema']
      return unless schema_object

      return unless schema_object

      @schema = Schema.new(schema_object, write: @operation.write?, openapi_version: @operation.openapi_version)
    end

    attr_reader :schema
  end
end

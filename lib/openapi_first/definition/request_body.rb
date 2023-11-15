# frozen_string_literal: true

require_relative 'media_type'

module OpenapiFirst
  class RequestBody
    def initialize(request_body_object, operation)
      @request_body_object = request_body_object
      @operation = operation
    end

    def description
      @request_body_object['description']
    end

    def required?
      !!@request_body_object['required']
    end

    def content_for(content_type)
      content = @request_body_object['content']
      media_type_object = content&.fetch(content_type) do |_|
        type = content_type.split(';')[0]
        content[type] || content["#{type.split('/')[0]}/*"] || content['*/*']
      end
      MediaType.new(media_type_object, @operation) if media_type_object
    end
  end
end

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
      content&.fetch(content_type) do |_|
        type = content_type.split(';')[0]
        content[type] || content["#{type.split('/')[0]}/*"] || content['*/*']
      end
    end

    private

    def content
      @content ||= @request_body_object.fetch('content', nil).dup.transform_values! do |media_type_object|
        MediaType.new(media_type_object, @operation)
      end
    end
  end
end

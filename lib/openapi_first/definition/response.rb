# frozen_string_literal: true

require_relative 'has_content'

module OpenapiFirst
  class Response
    include HasContent

    def initialize(status, response_object, operation)
      @status = status&.to_i
      @object = response_object
      @operation = operation
    end

    attr_reader :status

    def description
      @object['description']
    end

    def headers
      @object['headers']
    end

    def content?
      !!content&.any?
    end

    private

    def schema_write? = false

    def content
      @object['content']
    end
  end
end

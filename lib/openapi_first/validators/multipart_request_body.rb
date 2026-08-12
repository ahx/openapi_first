# frozen_string_literal: true

require_relative '../schema/validation_result'

module OpenapiFirst
  module Validators
    class MultipartRequestBody
      FILE_UPLOAD_PLACEHOLDER = String.new('', encoding: Encoding::BINARY).freeze

      def initialize(content_schema:)
        @schema = content_schema
      end

      def call(parsed_request)
        body = parsed_request.body
        return if body.nil?

        uploads = collect_file_uploads(body)
        uploads.each_key { write_at(body, _1, FILE_UPLOAD_PLACEHOLDER) }
        begin
          validate(body)
        ensure
          uploads.each { |path, upload| write_at(body, path, upload) }
        end
      end

      private

      def validate(body)
        validation = Schema::ValidationResult.new(
          @schema.validate(body, access_mode: 'write')
        )
        Failure.new(:invalid_body, errors: validation.errors) if validation.error?
      end

      def collect_file_uploads(value, path = [], result = {})
        case value
        when ::Hash
          if value.key?(:tempfile)
            result[path] = value unless path.empty?
          else
            value.each { |key, item| collect_file_uploads(item, path + [key], result) }
          end
        when ::Array
          value.each_with_index { |item, index| collect_file_uploads(item, path + [index], result) }
        end
        result
      end

      def write_at(root, path, value)
        *parents, key = path
        container = parents.empty? ? root : root.dig(*parents)
        container[key] = value if container
      end
    end
  end
end

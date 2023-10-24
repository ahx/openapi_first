# frozen_string_literal: true

module OpenapiFirst
  module ErrorResponse
    class Default
      ## @param status [Integer] The HTTP status code.
      ## @param title [String] The title of the error. Usually the name of the HTTP status code.
      ## @param location [Symbol] The location of the error (:request_body, :query, :header, :cookie, :path).
      ## @param validation_result [SchemaValidation::Result]
      def initialize(status:, location:, title:, validation_result:)
        @status = status
        @title = title
        @location = location
        @validation = validation_result
      end

      def render
        Rack::Response.new(body, status, Rack::CONTENT_TYPE => content_type).finish
      end

      private

      attr_reader :status, :location, :title, :validation

      def body
        MultiJson.dump({ errors: serialized_errors })
      end

      def serialized_errors
        return default_errors unless validation

        key = pointer_key
        [
          {
            source: { key => pointer(validation.result['instanceLocation']) },
            title: validation.result['error']
          }
        ]
      end

      def default_errors
        [{
          status: status.to_s,
          title:
        }]
      end

      def pointer_key
        case location
        when :request_body
          :pointer
        when :query, :path
          :parameter
        else
          location
        end
      end

      def pointer(data_pointer)
        return data_pointer if location == :request_body

        data_pointer.delete_prefix('/')
      end

      def content_type
        'application/json'
      end
    end
  end
end

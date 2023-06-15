# frozen_string_literal: true

module OpenapiFirst
  module ErrorResponse
    class Default
      # Initializes a new ErrorResponse.
      ## @param status [Integer] The HTTP status code.
      ## @param title [String] The title of the error. Usually the name of the HTTP status code.
      ## @param location [Symbol] The location of the error (:content, :query, :header, :cookie, :path).
      ## @param validation_errors [Array<Hash>] An array of (JSON Schema) validation errors.
      def initialize(status:, location:, title:, validation_errors: nil)
        @status = status
        @title = title
        @location = location
        @validation_errors = validation_errors
      end

      attr_reader :validation_errors, :status, :location, :title

      def render
        Rack::Response.new(MultiJson.dump(body), status, Rack::CONTENT_TYPE => content_type).finish
      end

      def body
        { errors: serialized_errors }
      end

      def serialized_errors
        return default_errors if validation_errors.nil?

        key = pointer_key
        validation_errors.map do |error|
          ErrorFormat.error_details(error).merge(source: { key => pointer(error['data_pointer']) })
        end
      end

      def pointer_key
        case location
        when :content
          :pointer
        when :query, :path
          :parameter
        else
          location
        end
      end

      def pointer(data_pointer)
        return data_pointer if location == :content

        data_pointer.delete_prefix('/')
      end

      def default_errors
        [{
          status: status.to_s,
          title: title
        }]
      end

      def content_type
        'application/json'
      end
    end
  end
end

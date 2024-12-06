# frozen_string_literal: true

require 'json'

module OpenapiFirst
  # @!visibility private
  module BodyParser
    def self.[](content_type)
      case content_type
      when /json/i
        JsonBodyParser
      when %r{multipart/form-data}i
        MultipartBodyParser
      else
        DefaultBodyParser
      end
    end

    def self.read_body(request)
      body = request.body&.read
      request.body.rewind if request.body.respond_to?(:rewind)
      body
    end

    JsonBodyParser = lambda do |request|
      body = read_body(request)
      return if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      Failure.fail!(:invalid_body, message: 'Failed to parse request body as JSON')
    end

    MultipartBodyParser = lambda do |request|
      request.POST.transform_values do |value|
        value.is_a?(Hash) && value[:tempfile] ? value[:tempfile].read : value
      end
    end

    # This returns the post data parsed by rack or the raw body
    DefaultBodyParser = lambda do |request|
      return request.POST if request.form_data?

      read_body(request)
    end
  end
end

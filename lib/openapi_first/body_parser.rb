# frozen_string_literal: true

require 'multi_json'

module OpenapiFirst
  # @!visibility private
  module BodyParser
    def self.[](content_type)
      case content_type
      when /json/i
        JSON
      when %r{multipart/form-data}i
        Multipart
      else
        Default
      end
    end

    def self.read_body(request)
      body = request.body&.read
      request.body.rewind if request.body.respond_to?(:rewind)
      body
    end

    JSON = lambda do |request|
      body = read_body(request)
      return if body.nil? || body.empty?

      MultiJson.load(body)
    rescue MultiJson::ParseError
      Failure.fail!(:invalid_body, message: 'Failed to parse request body as JSON')
    end

    Multipart = lambda do |request|
      request.POST.transform_values do |value|
        value.is_a?(Hash) && value[:tempfile] ? value[:tempfile].read : value
      end
    end

    # This returns the post data parsed by rack or the raw body
    Default = lambda do |request|
      return request.POST if request.form_data?

      read_body(request)
    end
  end
end

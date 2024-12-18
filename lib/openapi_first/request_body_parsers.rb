# frozen_string_literal: true

require 'json'

module OpenapiFirst
  # @!visibility private
  module RequestBodyParsers
    DEFAULT = ->(request) { Utils.read_body(request) }

    @parsers = {}

    class << self
      attr_reader :parsers

      def register(pattern, parser)
        parsers[pattern] = parser
      end

      def [](content_type)
        key = parsers.keys.find { content_type.match?(_1) }
        parsers.fetch(key) { DEFAULT }
      end
    end

    # Not sure where to put this
    module Utils
      def self.read_body(request)
        body = request.body&.read
        request.body.rewind if request.body.respond_to?(:rewind)
        body
      end
    end

    register(/json/i, lambda do |request|
      body = Utils.read_body(request)
      JSON.parse(body) unless body.nil? || body.empty?
    rescue JSON::ParserError
      Failure.fail!(:invalid_body, message: 'Failed to parse request body as JSON')
    end)

    register('multipart/form-data', lambda { |request|
      request.POST.transform_values do |value|
        value.is_a?(Hash) && value[:tempfile] ? value[:tempfile].read : value
      end
    })

    register('application/x-www-form-urlencoded', lambda(&:POST))
  end
end

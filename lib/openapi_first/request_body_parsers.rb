# frozen_string_literal: true

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

      def [](content_type, options = {})
        key = parsers.keys.find { content_type.match?(_1) }
        parser = parsers.fetch(key) { DEFAULT }
        return parser.new(options) if parser.is_a?(Class)

        parser
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
      Failure.new(:invalid_body, message: 'Failed to parse request body as JSON')
    end)

    # Honors the OpenAPI `encoding` map: when a top-level field has
    # `contentType: application/json` (or any */json), the field's raw value
    # is JSON-parsed before schema validation.
    class MultipartBodyParser
      def initialize(options)
        @encoding = options[:encoding] || {}
      end

      def call(request)
        result = {}
        request.POST.each do |name, value|
          decoded = decode_field(name, value)
          return decoded if decoded.is_a?(Failure)

          result[name] = decoded
        end
        result
      end

      private

      def decode_field(name, value)
        content_type = @encoding.dig(name, 'contentType')
        return unpack_value(value) unless content_type && json?(content_type)

        raw = read_raw(value)
        return unpack_value(value) if raw.nil?

        JSON.parse(raw)
      rescue JSON::ParserError => e
        Failure.new(:invalid_body,
                    message: %(Failed to parse multipart field "#{name}" as JSON: #{e.message}))
      end

      def json?(content_type)
        content_type.match?(%r{[/+]json\b}i)
      end

      def read_raw(value)
        return value if value.is_a?(String)

        value[:tempfile]&.read if value.is_a?(Hash) && value.key?(:tempfile)
      end

      def unpack_value(value)
        return value.map { unpack_value(_1) } if value.is_a?(Array)
        return value unless value.is_a?(Hash)
        return value if value.key?(:tempfile)

        value.transform_values { unpack_value(_1) }
      end
    end

    register(%r{\Amultipart/form-data\b}i, MultipartBodyParser)

    register('application/x-www-form-urlencoded', lambda(&:POST))
  end
end

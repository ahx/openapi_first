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
      Failure.new(:invalid_body, message: 'Failed to parse request body as JSON')
    end)

    # Parses multipart/form-data requests and currently puts the contents of a file upload at the parsed hash values.
    # NOTE: This behavior will probably change in the next major version.
    #       The uploaded file should not be read during request validation.
    #
    # Honors the OpenAPI `encoding` map: when a top-level field has
    # `contentType: application/json` (or any */json), the field's raw value
    # is JSON-parsed before schema validation.
    class MultipartBodyParser
      def initialize(encoding: {})
        @encoding = encoding || {}
      end

      def self.call(request)
        new.call(request)
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
        raw = unpack_value(value)
        content_type = @encoding.dig(name, 'contentType')
        return raw unless content_type && raw.is_a?(String) && json?(content_type)

        JSON.parse(raw)
      rescue JSON::ParserError => e
        Failure.fail!(:invalid_body,
                      message: %(Failed to parse multipart field "#{name}" as JSON: #{e.message}))
      end

      def json?(content_type)
        content_type.match?(%r{[/+]json\b}i)
      end

      def unpack_value(value)
        return value.map { unpack_value(_1) } if value.is_a?(Array)
        return value unless value.is_a?(Hash)
        return value[:tempfile]&.read if value.key?(:tempfile)

        value.transform_values { unpack_value(_1) }
      end
    end

    register('multipart/form-data', MultipartBodyParser)

    register('application/x-www-form-urlencoded', lambda(&:POST))
  end
end

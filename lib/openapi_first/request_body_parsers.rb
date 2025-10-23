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
      Failure.fail!(:invalid_body, message: 'Failed to parse request body as JSON')
    end)

    # Parses multipart/form-data requests and currently puts the contents of a file upload at the parsed hash values.
    # NOTE: This behavior will probably change in the next major version.
    #       The uploaded file should not be read during request validation.
    module MultipartBodyParser
      def self.call(request)
        call_with_encoding(request, {})
      end

      def self.call_with_encoding(request, encoding)
        request.POST.each_with_object({}) do |(key, value), result|
          parsed_value = unpack_value(value)
          
          # Apply encoding-specific parsing if specified
          if encoding.key?(key)
            part_encoding = encoding[key]
            content_type = part_encoding['contentType']
            
            if content_type && parsed_value.is_a?(String)
              parsed_value = parse_content_by_type(parsed_value, content_type, key)
            end
          end
          
          result[key] = parsed_value
        end
      end

      def self.parse_content_by_type(content, content_type, field_name)
        case content_type.downcase
        when 'application/json'
          begin
            JSON.parse(content)
          rescue JSON::ParserError => e
            # Log the parsing failure for debugging, but return original content to maintain compatibility
            warn "Warning: Failed to parse JSON for field '#{field_name}': #{e.message}. Returning original content."
            content
          end
        else
          # For other content types (like text/csv), return as-is for now
          content
        end
      end

      def self.unpack_value(value)
        return value.map { unpack_value(_1) } if value.is_a?(Array)
        return value unless value.is_a?(Hash)
        return value[:tempfile]&.read if value.key?(:tempfile)

        value.transform_values do |v|
          unpack_value(v)
        end
      end
    end

    register('multipart/form-data', MultipartBodyParser)

    register('application/x-www-form-urlencoded', lambda(&:POST))
  end
end

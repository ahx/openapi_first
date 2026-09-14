# frozen_string_literal: true

require 'json_schemer'

module OpenapiFirst
  module Schema
    # Support for the JSON Schema content keywords `contentEncoding`, `contentMediaType` and
    # `contentSchema`, which OpenAPI 3.1 inherits from JSON Schema 2020-12.
    #
    # JSON Schema defines them as annotations and lets implementations opt in to validating the
    # embedded document. openapi_first opts in: a string that cannot be decoded or parsed, or whose
    # parsed value does not match `contentSchema`, makes the request or response invalid.
    #
    # An encoding or media type that cannot be decoded at all (`image/png`, `base64url`) is ignored
    # instead of raising, so that OpenAPI 3.1 descriptions of binary payloads keep working.
    module Content
      Builtin = JSONSchemer::Draft202012::Vocab::Content
      private_constant :Builtin

      # Marks a result whose `annotation` holds the decoded or parsed value. A parsed value can be
      # `nil` (the JSON document `null`), so the annotation alone does not tell us whether decoding
      # succeeded.
      DECODED = { 'decoded' => true }.freeze
      private_constant :DECODED

      # @visibility private
      module Assertion
        private

        def decoded?(result) = result&.details&.fetch('decoded', false) == true

        # The content keywords only assert when there is a `contentSchema` to validate against.
        def assert? = schema.value.key?('contentSchema')
      end

      # Decodes the string. An unknown `contentEncoding` is ignored.
      class ContentEncoding < Builtin::ContentEncoding
        include Assertion

        def error(formatted_instance_location:, **)
          "string at #{formatted_instance_location} is not #{value} encoded"
        end

        def validate(instance, instance_location, keyword_location, _context)
          return result(instance, instance_location, keyword_location, true) if parsed.nil? || !instance.is_a?(String)

          valid, annotation = parsed.call(instance)
          return result(instance, instance_location, keyword_location, true, annotation:, details: DECODED) if valid

          result(instance, instance_location, keyword_location, !assert?)
        end

        private

        def parse
          root.fetch_content_encoding(value) { nil }
        end
      end

      # Parses the decoded string. An unknown `contentMediaType` (like `image/png`) is ignored.
      class ContentMediaType < Builtin::ContentMediaType
        include Assertion

        def error(formatted_instance_location:, **)
          "string at #{formatted_instance_location} is not valid #{value}"
        end

        def validate(instance, instance_location, keyword_location, context)
          return result(instance, instance_location, keyword_location, true) if parsed.nil? || !instance.is_a?(String)

          encoding = context.adjacent_results[ContentEncoding]
          return result(instance, instance_location, keyword_location, true) if encoding && !decoded?(encoding)

          valid, annotation = parsed.call(encoding ? encoding.annotation : instance)
          return result(instance, instance_location, keyword_location, true, annotation:, details: DECODED) if valid

          result(instance, instance_location, keyword_location, !assert?)
        end

        private

        def parse
          root.fetch_content_media_type(value) { nil }
        end
      end

      # Validates the parsed content against `contentSchema`.
      class ContentSchema < Builtin::ContentSchema
        include Assertion

        def error(formatted_instance_location:, details:)
          "string at #{formatted_instance_location} does not match `contentSchema`: " \
            "#{details.fetch('errors').join('. ')}"
        end

        def validate(instance, instance_location, keyword_location, context)
          media_type = context.adjacent_results[ContentMediaType]
          return result(instance, instance_location, keyword_location, true) unless decoded?(media_type)

          errors = parsed.validate(media_type.annotation)
          return result(instance, instance_location, keyword_location, true) if errors.first.nil?

          details = { 'errors' => errors.map { |error| error['error'] } }
          result(instance, instance_location, keyword_location, false, details:)
        end
      end

      VOCABULARY = {
        'contentEncoding' => ContentEncoding,
        'contentMediaType' => ContentMediaType,
        'contentSchema' => ContentSchema
      }.freeze
      private_constant :VOCABULARY

      # The OpenAPI 3.1 Schema Object dialect, with the content keywords above.
      # @return [JSONSchemer::Schema]
      def self.openapi31_dialect
        @openapi31_dialect ||= JSONSchemer::Schema.new(
          JSONSchemer::OpenAPI31::SCHEMA,
          base_uri: JSONSchemer::OpenAPI31::BASE_URI,
          formats: JSONSchemer::OpenAPI31::FORMATS,
          ref_resolver: JSONSchemer::OpenAPI31::Meta::SCHEMAS.to_proc,
          regexp_resolver: 'ecma'
        ).tap { |dialect| dialect.keywords = dialect.keywords.merge(VOCABULARY) }
      end
    end
  end
end

# frozen_string_literal: true

require 'json'

module OpenapiFirst
  module Parameters
    # Registry of parsers for parameters that use a `content` field, keyed by media type.
    #
    # A parser is a callable that takes a raw string and returns the parsed value.
    # It should `throw :skip, value` if the input cannot be parsed, so the
    # parameter value is used as is.
    #
    #   OpenapiFirst::Parameters::ContentParsers.register('application/xml', ->(value) { ... })
    module ContentParsers
      @parsers = []

      class << self
        attr_reader :parsers

        # @param matcher [String, Regexp] exact media type or a pattern.
        # @param parser [#call] callable that takes the raw string and returns the parsed value.
        def register(matcher, parser)
          parsers.reject! { |existing, _| existing == matcher }
          parsers << [matcher, parser]
        end

        # @param media_type [String, nil]
        # @return [#call, nil] the parser, or nil if none is registered.
        def [](media_type)
          return nil if media_type.nil?

          parsers.each do |matcher, parser|
            return parser if match?(matcher, media_type)
          end
          nil
        end

        private

        def match?(matcher, media_type)
          case matcher
          when Regexp then matcher.match?(media_type)
          else matcher == media_type
          end
        end
      end

      register(%r{\A[\w.+-]+/(?:[\w.-]+\+)?json\z}i, lambda do |value|
        JSON.parse(value)
      rescue JSON::ParserError
        throw :skip, value
      end)
    end
  end
end

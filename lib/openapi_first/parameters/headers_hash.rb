# frozen_string_literal: true

module OpenapiFirst
  module Parameters
    # A wrapper around the Rack env hash that allows accessing headers by header name
    # @visibility private
    class HeadersHash
      # This was copied from this Rack::Request PR: https://github.com/rack/rack/pull/1881
      def initialize(env)
        @env = env
      end

      def [](key)
        @env[header_to_env_key(key)]
      end

      def key?(key)
        @env.key?(header_to_env_key(key))
      end

      def header_to_env_key(key)
        key = key.upcase
        key.tr!('-', '_')
        key = "HTTP_#{key}" unless %w[CONTENT_LENGTH CONTENT_TYPE].include?(key)
        key
      end
    end
  end
end

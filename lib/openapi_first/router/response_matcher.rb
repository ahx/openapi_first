# frozen_string_literal: true

require_relative 'content_matcher'

module OpenapiFirst
  class Router
    # Finds a matching response from a list of responses
    class ResponseMatcher
      Match = Data.define(:response, :error)

      include Enumerable

      def initialize
        @responses = {}
      end

      def add_response(status, content_type, response)
        content_matcher = (@responses[status.to_s] ||= ContentMatcher.new)
        content_matcher[content_type] = response
      end

      def each(&block)
        @responses.each_value do |content|
          content.values.each(&block)
        end
      end

      def match(status, content_type)
        contents = self[status]
        if contents.nil?
          message = "Response status #{status} is not defined. Defined statuses are: #{@responses.keys.join(', ')}."
          return Match.new(error: Failure.new(:response_not_found, message:), response: nil)
        end
        response = contents[content_type]
        if response.nil?
          message = "#{content_error(content_type)} Content-Type should be #{contents.keys.join(' or ')}."
          return Match.new(error: Failure.new(:response_not_found, message:), response: nil)
        end

        Match.new(response:, error: nil)
      end

      private

      def content_error(content_type)
        return 'Content-Type must not be empty.' if content_type.nil? || content_type.empty?

        "Content-Type #{content_type} is not defined."
      end

      def [](status)
        # According to OAS status has to be a string,
        # but there are a few API descriptions out there that use integers because of YAML.
        # return @responses[status] if @responses.key?(status)

        @responses[status.to_s] ||
          @responses["#{status / 100}XX"] ||
          @responses["#{status / 100}xx"] ||
          @responses['default']
      end
    end
  end
end

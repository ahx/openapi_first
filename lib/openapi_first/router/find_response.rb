# frozen_string_literal: true

require_relative 'find_content'

module OpenapiFirst
  class Router
    # @visibility private
    module FindResponse
      Match = Data.define(:response, :error)

      def self.call(responses, status, content_type, request_method:, path:)
        contents = find_status(responses, status)
        if contents.nil?
          message = "Status #{status} is not defined for #{request_method} #{path}. " \
                    "Defined statuses are: #{responses.keys.join(', ')}."
          return Match.new(error: Failure.new(:response_not_found, message:), response: nil)
        end
        response = FindContent.call(contents, content_type)
        if response.nil?
          message = "#{content_error(content_type, request_method:,
                                                   path:)} Content-Type should be #{contents.keys.join(' or ')}."
          return Match.new(error: Failure.new(:response_not_found, message:), response: nil)
        end

        Match.new(response:, error: nil)
      end

      def self.content_error(content_type, request_method:, path:)
        return 'Response Content-Type must not be empty.' if content_type.nil? || content_type.empty?

        "Response Content-Type #{content_type} is not defined for #{request_method} #{path}."
      end

      def self.find_status(responses, status)
        # According to OAS status has to be a string,
        # but there are a few API descriptions out there that use integers because of YAML.

        responses[status] || responses[status.to_s] ||
          responses["#{status / 100}XX"] ||
          responses["#{status / 100}xx"] ||
          responses['default']
      end
    end
  end
end

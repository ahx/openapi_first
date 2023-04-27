# frozen_string_literal: true

module OpenapiFirst
  module ErrorResponse
    class << self
      # Throws an error in the middle of the request validation to stop validation and send a response.
      def throw_error(status, errors = [default_error(status)])
        throw :error, {
          status: status,
          errors: errors
        }
      end

      # Renders the actual Rack error response.
      def render(error)
        Rack::Response.new(
          MultiJson.dump(errors: error.fetch(:errors)),
          error[:status] || 400,
          Rack::CONTENT_TYPE => 'application/vnd.api+json'
        ).finish
      end

      private

      def default_error(status, title = Rack::Utils::HTTP_STATUS_CODES[status])
        {
          status: status.to_s,
          title: title
        }
      end
    end
  end
end

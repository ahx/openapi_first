# frozen_string_literal: true

module OpenapiFirst
  module Test
    # Assertion methods to use when no known test framework was found
    # These methods just raise an exception if an error was found
    module PlainHelpers
      # Validates the last request and response of rack-test against the API description.
      # @param status [Integer, nil] The expected response status
      # @param api [Symbol, Definition] The registered API description
      def assert_api_conform(status: nil, api: openapi_first_default_api)
        api = OpenapiFirst::Test[api]
        # simplecov:disable
        request = respond_to?(:last_request) ? last_request : @request
        response = respond_to?(:last_response) ? last_response : @response
        # simplecov:disable

        if status && status != response.status
          raise OpenapiFirst::Error,
                "Expected status #{status}, but got #{response.status} " \
                "from #{request.request_method.upcase} #{request.path}."
        end

        validated = api.validate_request(request, raise_error: false)
        # simplecov:disable
        raise validated.error.exception if validated.invalid?

        validated = api.validate_response(request, response, raise_error: false)
        raise validated.error.exception if validated.invalid?
        # simplecov:disable
      end
    end
  end
end

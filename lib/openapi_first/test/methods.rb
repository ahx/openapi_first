# frozen_string_literal: true

module OpenapiFirst
  module Test
    # Methods to use in integration tests
    module Methods
      def assert_api_conform(status: nil, api: :default)
        api = OpenapiFirst::Test[api]
        request = respond_to?(:last_request) ? last_request : @request
        response = respond_to?(:last_response) ? last_response : @response
        if status && status != response.status
          raise OpenapiFirst::Error,
                "Expected status #{status}, but got #{response.status} " \
                "from #{request.request_method.upcase} #{request.path}."
        end
        api.validate_request(request, raise_error: true)
        api.validate_response(request, response, raise_error: true)
      end
    end
  end
end

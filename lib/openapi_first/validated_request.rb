# frozen_string_literal: true

require 'forwardable'

module OpenapiFirst
  # A validated request (see RuntimeRequest). It can be valid or not.
  class ValidatedRequest
    extend Forwardable

    def initialize(request, error)
      @request = request
      @error = error
    end

    def_delegators :@request, :content_type, :media_type, :operation, :path, :path_item, :path_parameters, :query,
                   :headers, :cookies, :body, :operation_id, :request_method,
                   :known?, :known_path?, :known_request_method?

    alias query_parameters query
    alias parsed_body body

    # Returns the error object if validation failed.
    # @return [Failure, nil]
    attr_reader :error

    # Checks if the request is valid.
    # @return [Boolean] true if the request is valid, false otherwise.
    def valid?
      error.nil?
    end

    # Returns the merged path and query parameters.
    # @return [Hash] The merged path and query parameters.
    def params
      @params ||= query.merge(path_parameters)
    end
  end
end

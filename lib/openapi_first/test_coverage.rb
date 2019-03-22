module OpenapiFirst
  class TestCoverage
    attr_reader :to_be_called

    def initialize(app, spec)
      @app = app
      @spec = spec
      @to_be_called = spec.endpoints.map do |endpoint|
        endpoint_id(endpoint)
      end
    end

    def call(env)
      endpoint = endpoint_for_request(Rack::Request.new(env))
      @to_be_called.delete(endpoint_id(endpoint)) if endpoint
      @app.call(env)
    end

    private

    def endpoint_id(endpoint)
      "#{endpoint.path.path}##{endpoint.method}"
    end

    def endpoint_for_request(request)
      @spec
        .path_by_path(request.path)
        .endpoint_by_method(request.request_method.downcase)
      rescue OasParser::PathNotFound => error
        warn error.message
    end
  end
end

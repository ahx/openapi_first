module OpenapiFirst
  class Coverage
    attr_reader :to_be_called

    def initialize(app, spec)
      @app = app
      @spec = spec
      @to_be_called = spec.endpoints.map do |endpoint|
        endpoint_id(endpoint)
      end
    end

    def call(env)
      id = endpoint_id_for_request(Rack::Request.new(env))
      @to_be_called.delete(id)
      @app.call(env)
    end

    private

    def endpoint_id(endpoint)
      "#{endpoint.path.path}##{endpoint.method}"
    end

    def endpoint_id_for_request(request)
      endpoint = @spec
                 .path_by_path(request.path)
                 .endpoint_by_method(request.request_method.downcase)
      endpoint_id(endpoint)
    end
  end
end

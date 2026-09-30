# frozen_string_literal: true

require 'benchmark/memory'
require 'openapi_first'

Benchmark.memory do |x|
  x.report do
    oad = OpenapiFirst.load('../spec/data/large.yaml')
    oad.routes.select { _1.request_method == 'GET' }.each do |route|
      path = route.path.gsub(/\{[^}]+\}/, '1')
      request = Rack::Request.new(Rack::MockRequest.env_for(path))
      2.times { oad.validate_request(request) }
    end
  end
end

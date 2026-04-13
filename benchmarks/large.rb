# frozen_string_literal: true

require 'benchmark/memory'
require 'openapi_first'

Benchmark.memory do |x|
  x.report do
    oad = OpenapiFirst.load('../spec/data/large.yaml')
    request = Rack::Request.new(Rack::MockRequest.env_for('/workspaces'))
    oad.validate_request(request)
  end
end

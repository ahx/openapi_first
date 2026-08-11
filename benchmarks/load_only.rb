# frozen_string_literal: true

require 'benchmark/memory'
require 'openapi_first'

# Keep every loaded Definition reachable, like OpenapiFirst.register would in a real app,
# so "retained" reflects the object graph an app actually keeps in memory long-term.
loaded = []

Benchmark.memory do |x|
  x.report('load large.yaml') do
    loaded << OpenapiFirst.load('../spec/data/large.yaml')
  end

  x.report('load train-travel-api') do
    loaded << OpenapiFirst.load('../spec/data/train-travel-api/openapi.yaml')
  end
end

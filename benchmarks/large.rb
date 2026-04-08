# frozen_string_literal: true

require 'benchmark/memory'
require 'openapi_first'

Benchmark.memory do |x|
  x.report { OpenapiFirst.load('../spec/data/large.yaml') }
end

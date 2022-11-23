# frozen_string_literal: true

require 'benchmark/ips'
require 'benchmark/memory'
require 'rack'
require 'json'
ENV['RACK_ENV'] = 'production'

examples = [
  [Rack::MockRequest.env_for('/hello'), 200],
  [Rack::MockRequest.env_for('/unknown'), 404],
  [
    Rack::MockRequest.env_for('/hello', method: 'POST', input: JSON.dump({ say: 'hi!' }),
                                        'CONTENT_TYPE' => 'application/json'), 201
  ],
  [Rack::MockRequest.env_for('/hello/1'), 200],
  [Rack::MockRequest.env_for('/hello/123'), 200],
  [Rack::MockRequest.env_for('/hello?filter[id]=1,2'), 200]
]

glob = ARGV[0] || './apps/*.ru'
apps = Dir[glob].each_with_object({}) do |config, hash|
  hash[config] = Rack::Builder.parse_file(config).first
end
apps.freeze

bench = lambda do |app|
  examples.each do |example|
    env, expected_status = example
    100.times { app.call(env) }
    response = app.call(env)
    raise "expected status #{expected_status}, but was #{response[0]}" unless response[0] == expected_status
  end
end

Benchmark.ips do |x|
  apps.each do |config, app|
    x.report(config) { bench.call(app) }
  end
  x.compare!
end

Benchmark.memory do |x|
  apps.each do |config, app|
    x.report(config) { bench.call(app) }
  end
  x.compare!
end

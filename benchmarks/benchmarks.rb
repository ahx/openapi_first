# frozen_string_literal: true

require 'benchmark/ips'
require 'benchmark/memory'
require 'rack'
ENV['RACK_ENV'] = 'production'

examples = [
  [Rack::MockRequest.env_for('/hello'), 200],
  [Rack::MockRequest.env_for('/unknown'), 404],
  [Rack::MockRequest.env_for('/hello', method: 'POST'), 201],
  [Rack::MockRequest.env_for('/hello/1'), 200],
  [Rack::MockRequest.env_for('/hello/123'), 200],
  [Rack::MockRequest.env_for('/hello?filter[id]=1,2'), 200]
]

apps = Dir['./apps/*.ru'].each_with_object({}) do |config, hash|
  hash[config] = Rack::Builder.parse_file(config).first
end
apps.freeze

Benchmark.ips do |x|
  apps.each do |config, app|
    x.report(config) do
      examples.each do |example|
        env, expected_status = example
        response = app.call(env)
        raise unless response[0] == expected_status
      end
    end
  end
  x.compare!
end

Benchmark.memory do |x|
  apps.each do |config, app|
    x.report(config) do
      examples.each do |example|
        env, expected_status = example
        response = app.call(env)
        raise unless response[0] == expected_status
      end
    end
  end
  x.compare!
end

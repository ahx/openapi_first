# frozen_string_literal: true

require 'benchmark/ips'
require 'rack'
ENV['RACK_ENV'] = 'production'

configs = Dir['./apps/*.ru']

Benchmark.ips do |x|
  requests = [
    Rack::MockRequest.env_for('/hello'),
    Rack::MockRequest.env_for('/unknown'),
    Rack::MockRequest.env_for('/hello', method: 'POST'),
    Rack::MockRequest.env_for('/hello/1'),
    Rack::MockRequest.env_for('/hello/123')
  ]

  configs.each do |config|
    app = Rack::Builder.parse_file(config).first
    x.report(config) do
      requests.each { |env| app.call(env) }
    end
  end

  x.compare!
end

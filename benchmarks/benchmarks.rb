# frozen_string_literal: true

require 'benchmark/ips'
require 'rack'

configs = Dir['./apps/*.ru']

Benchmark.ips do |x|
  env = Rack::MockRequest.env_for('/hello')

  configs.each do |config|
    app = Rack::Builder.parse_file(config).first
    x.report(config) do
      res = app.call(env)
      raise unless res[0] == 200
    end
  end

  x.compare!
end

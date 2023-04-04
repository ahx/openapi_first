# frozen_string_literal: true

require 'openapi_first'
require 'rack'

App = Rack::Builder.new do
  use OpenapiFirst::RequestValidation, raise_error: true, spec: File.expand_path('./openapi.yaml', __dir__)
  use OpenapiFirst::ResponseValidation

  map '/' do
    run(lambda do |_env|
      [200, { 'Content-Type' => 'application/json' }, ['{"hello": "world"}']]
    end)
  end
end

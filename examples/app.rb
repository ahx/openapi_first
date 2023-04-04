# frozen_string_literal: true

require 'openapi_first'

App = Rack::Builder.new do
  use OpenapiFirst::RequestValidation, raise_error: true, spec: File.expand_path('./openapi.yaml', __dir__)
  use OpenapiFirst::ResponseValidation

  handlers = {
    '/' => {
      'GET' => lambda do |_env|
        [200, { 'Content-Type' => 'application/json' }, ['{"hello": "world"}']]
      end
    }
  }
  run(lambda do |env|
    handlers[env['PATH_INFO']][env['REQUEST_METHOD']].call(env)
  end)
end

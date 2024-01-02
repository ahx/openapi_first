# frozen_string_literal: true

require 'openapi_first'
require 'rack'

# This example is a bit contrived, but it shows what you could do with the middlewares

App = Rack::Builder.new do
  use OpenapiFirst::RequestValidation, raise_error: true, spec: File.expand_path('./openapi.yaml', __dir__)
  use OpenapiFirst::ResponseValidation, spec: File.expand_path('./openapi.yaml', __dir__)

  handlers = {
    'things#index' => ->(_env) { [200, { 'Content-Type' => 'application/json' }, ['{"hello": "world"}']] }
  }
  not_found = ->(_env) { [404, {}, []] }

  run ->(env) { handlers.fetch(env[OpenapiFirst::REQUEST].operation_id, not_found).call(env) }
end

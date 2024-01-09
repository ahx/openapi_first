# frozen_string_literal: true

require 'openapi_first'
require 'rack'

# This example is a bit contrived, but it shows what you could do with the middlewares

App = Rack::Builder.new do
  spec = OpenapiFirst.load(File.expand_path('./openapi.yaml', __dir__))
  use(OpenapiFirst::Middlewares::RequestValidation, raise_error: true, spec:)
  use(OpenapiFirst::Middlewares::ResponseValidation, spec:)

  handlers = {
    'things#index' => ->(_env) { [200, { Rack::CONTENT_TYPE => 'application/json' }, ['{"hello": "world"}']] }
  }
  not_found = ->(_env) { [404, {}, []] }

  run ->(env) { handlers.fetch(env[OpenapiFirst::REQUEST].operation_id, not_found).call(env) }
end

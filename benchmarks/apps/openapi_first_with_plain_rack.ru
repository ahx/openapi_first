# frozen_string_literal: true

require 'multi_json'
require 'openapi_first'

app = Rack::Builder.new do
  use OpenapiFirst::RequestValidation, spec: File.expand_path('./openapi.yaml', __dir__)

  handlers = {
    'find_thing' => lambda do |env|
      params = env[OpenapiFirst::PARAMS]
      body = MultiJson.dump(hello: 'world', id: params.fetch('id'))
      [200, { 'Content-Type' => 'application/json' }, [body]]
    end,
    'find_things' => lambda do |_env|
      body = MultiJson.dump(hello: 'world')
      [200, { 'Content-Type' => 'application/json' }, [body]]
    end,
    'create_thing' => lambda do |_env|
      body = MultiJson.dump(hello: 'world')
      [201, { 'Content-Type' => 'application/json' }, [body]]
    end
  }

  not_found = ->(_env) { [404, {}, []] }

  run(lambda do |env|
    handlers.fetch(env[OpenapiFirst::OPERATION]&.operation_id, not_found).call(env)
  end)
end

run app

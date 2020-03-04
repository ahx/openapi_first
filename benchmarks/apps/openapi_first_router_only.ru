# frozen_string_literal: true

require 'multi_json'
require 'openapi_first'

namespace = {
  'find_thing' => Rack::Response.new(MultiJson.dump(hello: 'world', id: '1')).finish,
  'find_things' => Rack::Response.new(MultiJson.dump([{hello: 'world', id: '1'}])).finish,
  'create_thing' => Rack::Response.new(MultiJson.dump([{hello: 'world', id: '1'}]), 201).finish
}

spec = OpenapiFirst.load(File.absolute_path('./openapi.yaml', __dir__))
use OpenapiFirst::Router, spec: spec
run ->(env) {
  namespace.fetch(env[OpenapiFirst::OPERATION].operation_id)
}

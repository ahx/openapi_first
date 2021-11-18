# frozen_string_literal: true

require 'multi_json'
require 'openapi_first'

namespace = Module.new do
  def self.find_thing(params, _res)
    { hello: 'world', id: params.fetch(:id) }
  end

  def self.find_things(_params, _res)
    [{ hello: 'world' }]
  end

  def self.create_thing(_params, res)
    res.status = 201
    { hello: 'world' }
  end
end

oas_path = File.absolute_path('./openapi.yaml', __dir__)
run OpenapiFirst.app(oas_path, namespace: namespace, response_validation: true)

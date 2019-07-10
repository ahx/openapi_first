# frozen_string_literal: true

require 'openapi_first'

namespace = Module.new do
  def self.find_thing(_params, _res)
    { hello: 'world' }
  end
end

oas_path = File.absolute_path('./openapi.yaml', __dir__)
run OpenapiFirst.app(oas_path, namespace: namespace)

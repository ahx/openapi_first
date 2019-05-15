# frozen_string_literal: true

require 'openapi_first'

module Example
  def self.find_thing(_params, _res)
    { hello: 'world' }
  end
end

oas_path = File.absolute_path('./openapi.yaml', __dir__)
App = OpenapiFirst::App.new(oas_path, namespace: Example)

# frozen_string_literal: true

require 'openapi_first'
require 'syro'
require 'multi_json'

app = Syro.new do
  on 'hello' do
    on :id do
      get do
        res.json MultiJson.dump(hello: 'world', id: inbox[:id])
      end
    end

    get do
      res.json [MultiJson.dump(hello: 'world')]
    end

    post do
      res.status = 201
      res.json MultiJson.dump(hello: 'world')
    end
  end
end

spec = OpenapiFirst.load(File.absolute_path('./openapi.yaml', __dir__))
use OpenapiFirst::Router, spec: spec
use OpenapiFirst::RequestValidation

run app

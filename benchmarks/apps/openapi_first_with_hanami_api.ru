# frozen_string_literal: true

require 'multi_json'
require 'openapi_first'
require 'hanami/api'

app = Class.new(Hanami::API) do
  get '/hello/:id' do
    json(hello: 'world', id: params.fetch(:id))
  end

  get '/hello' do
    json([{ hello: 'world' }])
  end

  post '/hello' do
    status 201
    json(hello: 'world')
  end
end.new

oas_path = File.absolute_path('./openapi.yaml', __dir__)
use OpenapiFirst::Router, spec: OpenapiFirst.load(oas_path)
use OpenapiFirst::RequestValidation

run app

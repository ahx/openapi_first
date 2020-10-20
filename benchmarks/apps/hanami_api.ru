# frozen_string_literal: true

require 'multi_json'
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

run app

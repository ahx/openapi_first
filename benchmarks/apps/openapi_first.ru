# frozen_string_literal: true

require 'json'
require 'openapi_first'
require 'sinatra'

class SinatraWithOpenapiFirstExample < Sinatra::Base
  set :environment, :production

  get '/hello/:id' do
    content_type :json
    JSON.generate(hello: 'world', id: params.fetch('id'))
  end

  get '/hello' do
    content_type :json
    JSON.generate([{ hello: 'world' }])
  end

  post '/hello' do
    content_type :json
    status 201
    JSON.generate(hello: 'world')
  end
end

use OpenapiFirst::Middlewares::RequestValidation, spec: File.absolute_path('./openapi.yaml', __dir__)

run SinatraWithOpenapiFirstExample

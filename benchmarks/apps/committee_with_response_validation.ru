# frozen_string_literal: true

require 'multi_json'
require 'committee'
require 'sinatra'

app = Class.new(Sinatra::Base) do
  set :environment, :production

  get '/hello/:id' do
    content_type :json
    MultiJson.dump(hello: 'world', id: params.fetch('id'))
  end

  get '/hello' do
    content_type :json
    MultiJson.dump([{ hello: 'world' }])
  end

  post '/hello' do
    content_type :json
    status 201
    MultiJson.dump(hello: 'world')
  end
end

use Committee::Middleware::RequestValidation,
    schema_path: File.absolute_path('./openapi.yaml', __dir__),
    parse_response_by_content_type: true

use Committee::Middleware::ResponseValidation,
    schema_path: File.absolute_path('./openapi.yaml', __dir__),
    strict: true

run app

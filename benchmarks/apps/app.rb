# frozen_string_literal: true

require 'sinatra/base'

class App < Sinatra::Base
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

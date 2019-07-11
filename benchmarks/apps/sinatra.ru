# frozen_string_literal: true

require 'multi_json'
require 'sinatra/base'

class SinatraExample < Sinatra::Base
  set :environment, :production

  get '/hello/:id' do
    content_type :json
    MultiJson.dump(hello: 'world', id: params.fetch('id'))
  end

  get '/hello' do
    content_type :json
    [MultiJson.dump(hello: 'world')]
  end

  post '/hello' do
    content_type :json
    status 201
    MultiJson.dump(hello: 'world')
  end
end

run SinatraExample

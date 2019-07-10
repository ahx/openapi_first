# frozen_string_literal: true

require 'multi_json'
require 'sinatra/base'

app = Class.new(Sinatra::Base) do
  get '/hello' do
    content_type :json
    MultiJson.dump(hello: 'world')
  end
end

run app

# frozen_string_literal: true

require 'grape'

class GrapeExample < Grape::API
  format :json

  get :hello do
    [{ hello: 'world' }]
  end

  post :hello do
    { hello: 'world' }
  end

  get 'hello/:id' do
    { hello: 'world', id: params[:id] }
  end
end

run GrapeExample

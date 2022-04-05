# frozen_string_literal: true

require 'roda'
require 'multi_json'

class App < Roda
  route do |r|
    r.on 'hello' do
      r.on :id do
        r.get do
          MultiJson.dump({ hello: 'world', id: r.params[:id] })
        end
      end

      r.get do
        MultiJson.dump([{ hello: 'world' }])
      end

      r.post do
        response.status = 201
        MultiJson.dump({ hello: 'world' })
      end
    end
  end
end

run App.freeze.app

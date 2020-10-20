# frozen_string_literal: true

require 'syro'
require 'multi_json'

app = Syro.new do
  on 'hello' do
    on :id do
      get do
        res.json({ hello: 'world', id: inbox[:id] })
      end
    end

    get do
      res.json([{ hello: 'world' }])
    end

    post do
      res.status = 201
      res.json({ hello: 'world' })
    end
  end
end

run app

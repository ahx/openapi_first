# frozen_string_literal: true

require 'syro'
require 'multi_json'

app = Syro.new do
  on 'hello' do
    get do
      res.json MultiJson.dump(hello: 'world')
    end
  end
end

run app

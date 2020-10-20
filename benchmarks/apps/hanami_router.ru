# frozen_string_literal: true

require 'hanami/router'
require 'multi_json'

app = Hanami::Router.new do
  get '/hello', to: ->(_env) { [200, {}, [MultiJson.dump([{ hello: 'world' }])]] }
  get '/hello/:id', to: lambda { |env|
    [200, {}, [MultiJson.dump(hello: 'world', id: env['router.params'][:id])]]
  }
  post '/hello', to: ->(_env) { [201, {}, [MultiJson.dump(hello: 'world')]] }
end

run app

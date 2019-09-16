require 'committee'
require 'syro'
require 'multi_json'

app = Syro.new do
  on 'hello' do
    on :id do
      get do
        res.json MultiJson.dump(hello: 'world', id: inbox[:id])
      end
    end

    get do
      res.json [MultiJson.dump(hello: 'world')]
    end

    post do
      res.status = 201
      res.json MultiJson.dump(hello: 'world')
    end
  end
end

use Committee::Middleware::RequestValidation, schema_path: './apps/openapi.yaml', coerce_date_times: false

run app

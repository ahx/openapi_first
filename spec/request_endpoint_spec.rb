# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first/request_endpoint'

RSpec.describe OpenapiFirst::RequestEndpoint do
  API_SPEC = OpenapiFirst.load('./spec/data/openapi/petstore.yaml')

  describe '#call' do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use OpenapiFirst::RequestEndpoint, spec: API_SPEC
        run lambda { |_env|
          Rack::Response.new('hello', 200)
        }
      end
    end

    let(:path) do
      '/pets'
    end

    let(:query_params) do
      {}
    end

    it 'returns 404 if path is not found' do
      query_params.delete('term')
      get '/unknown', query_params

      expect(last_response.status).to be 404
      expect(last_response.body).to eq ''
    end

    it 'returns 404 if method is not found' do
      query_params.delete('term')
      delete path, query_params

      expect(last_response.status).to be 404
      expect(last_response.body).to eq ''
    end

    it 'adds the endpoint to env ' do
      env = Rack::MockRequest.env_for(path, params: query_params)
      app.call(env)

      endpoint = env[OpenapiFirst::ENDPOINT]
      expect(endpoint.path.path).to eq path
      expect(endpoint.method).to eq 'get'
    end

    describe('allow_unknown_endpoint: true') do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::RequestEndpoint,
              spec: API_SPEC,
              allow_unknown_endpoint: true
          run lambda { |_env|
            Rack::Response.new('hello', 200)
          }
        end
      end

      it 'calls the app' do
        get path, query_params

        expect(last_response.status).to be 200
        expect(last_response.body).to eq 'hello'
      end
    end
  end
end

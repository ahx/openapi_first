# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first/router'

RSpec.describe OpenapiFirst::Router do
  include Rack::Test::Methods

  describe '#call' do
    let(:app) do
      Rack::Builder.new do
        use OpenapiFirst::Router,
            spec: OpenapiFirst.load('./spec/data/petstore.yaml'),
            namespace: Web
        run ->(_env) { Rack::Response.new('hello', 200).finish }
      end
    end

    let(:path) do
      '/pets'
    end

    let(:query_params) do
      {}
    end

    before do
      namespace = double(
        :namespace,
        list_pets: nil,
        show_pet_by_id: nil
      )
      stub_const('Web', namespace)
    end

    it 'returns 404 if path is not found' do
      query_params.delete('term')
      get '/unknown', query_params

      expect(last_response.status).to be 404
      expect(last_response.body).to eq ''
    end

    it 'returns 400 if method is not found' do
      query_params.delete('term')
      delete path, query_params

      expect(last_response.status).to be 404
      expect(last_response.body).to eq ''
    end

    it 'adds the operation to env ' do
      get path, query_params

      operation = last_request.env[OpenapiFirst::OPERATION]
      expect(operation.operation_id).to eq 'listPets'
    end

    describe 'respecting SCRIPT_NAME' do
      let(:failure_app) do
        ->(_env) { Rack::Response.new.finish  }
      end

      let(:upstream_app) do
        ->(_env) { Rack::Response.new.finish  }
      end

      let(:app) do
        OpenapiFirst::Router.new(
          upstream_app,
          parent_app: failure_app,
          spec: OpenapiFirst.load('./spec/data/petstore.yaml'),
          namespace: Web
        )
      end

      it 'uses SCRIPT_NAME to build the whole path' do
        env = Rack::MockRequest.env_for('/42', script_name: '/pets')

        expect(upstream_app).to receive(:call) do |cenv|
          expect(cenv[Rack::SCRIPT_NAME]).to eq '/pets'
          expect(cenv[Rack::PATH_INFO]).to eq '/42'
        end

        app.call(env)
        operation = env[OpenapiFirst::OPERATION]
        expect(operation.operation_id).to eq 'showPetById'

        expect(env[Rack::SCRIPT_NAME]).to eq '/pets'
        expect(env[Rack::PATH_INFO]).to eq '/42'
      end

      it 'calls parent app with original env if route was not found' do
        env = Rack::MockRequest.env_for('/42', script_name: '/unknown')

        expect(failure_app).to receive(:call) do |cenv|
          expect(cenv[Rack::SCRIPT_NAME]).to eq '/unknown'
          expect(cenv[Rack::PATH_INFO]).to eq '/42'
        end

        app.call(env)

        expect(env[Rack::SCRIPT_NAME]).to eq '/unknown'
        expect(env[Rack::PATH_INFO]).to eq '/42'
      end
    end

    describe 'path parameters' do
      it 'adds path parameters to env ' do
        get '/pets/1'

        params = last_request.env[OpenapiFirst::PARAMS]
        expect(params).to eq('petId' => '1')
      end

      it 'does not add path parameters if not defined for operation' do
        expect(Mustermann::Template).to_not receive(:new)
        get 'pets'

        params = last_request.env[OpenapiFirst::PARAMS]
        expect(params).to be_empty
      end
    end

    describe 'query parameters' do
      it 'adds query parameters to env ' do
        get '/pets?limit=2'

        params = last_request.env[OpenapiFirst::PARAMS]
        expect(params).to eq('limit' => '2')
      end
    end

    describe('allow_unknown_operation: true') do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::Router,
              spec: OpenapiFirst.load('./spec/data/petstore.yaml'),
              allow_unknown_operation: true,
              namespace: Web
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end
    end
  end
end

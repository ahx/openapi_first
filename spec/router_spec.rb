# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first/router'

PETSTORE_SPEC = OpenapiFirst.load('./spec/data/petstore.yaml')

RSpec.describe OpenapiFirst::Router do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.new do
      use OpenapiFirst::Router, spec: PETSTORE_SPEC, namespace: namespace
      run lambda { |_env|
        Rack::Response.new('hello', 200).finish
      }
    end
  end

  describe '#call' do
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

    it 'adds the operation to env ' do
      get path, query_params

      operation = last_request.env[OpenapiFirst::OPERATION]
      expect(operation.operation_id).to eq 'listPets'
    end

    describe 'path parameters' do
      it 'adds path parameters to env ' do
        get '/pets/1'

        params = last_request.env[OpenapiFirst::PATH_PARAMS]
        expect(params).to eq(petId: '1')
      end

      it 'does not add path parameters if not defined for operation' do
        expect(Mustermann::Template).to_not receive(:new)
        get 'pets'

        params = last_request.env[OpenapiFirst::PATH_PARAMS]
        expect(params).to be_empty
      end
    end

    describe('allow_unknown_operation: true') do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::Router,
              spec: PETSTORE_SPEC,
              allow_unknown_operation: true,
              namespace: namespace
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end

      it 'allow unkown operation' do
        get '/unknown', query_params

        expect(last_response.status).to be 200
        expect(last_response.body).to eq 'hello'
      end
    end
  end
end

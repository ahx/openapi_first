# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first/router'

RSpec.describe OpenapiFirst::Router do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.new do
      use OpenapiFirst::Router,
          spec: OpenapiFirst.load('./spec/data/petstore.yaml'),
          namespace: Web
      run ->(_env) { Rack::Response.new('hello', 200).finish }
    end
  end

  describe '#call' do
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

  describe '#find_handler' do
    let(:router) do
      described_class.new(
        nil,
        spec: OpenapiFirst.load('./spec/data/petstore.yaml'),
        namespace: Web
      )
    end

    before do
      stub_const(
        'Web',
        Module.new do
          def self.some_method(_params, _res); end
        end
      )
      stub_const(
        'Web::Things',
        Class.new do
          def self.some_class_method(_params, _res); end
        end
      )
      stub_const(
        'Web::Things::Index',
        Class.new do
          def call(_params, _res); end
        end
      )
    end

    it 'finds some_method' do
      expect(Web).to receive(:some_method)
      router.find_handler('some_method').call
    end

    it 'finds things.some_method' do
      expect(Web::Things).to receive(:some_class_method)
      router.find_handler('things.some_class_method').call
    end

    it 'finds things#index' do
      expect_any_instance_of(Web::Things::Index).to receive(:call)
      router.find_handler('things#index').call(double, double)
    end

    it 'does not find inherited constants' do
      expect(router.find_handler('string.to_s')).to be_nil
      expect(router.find_handler('::string.to_s')).to be_nil
    end

    it 'does not find nested constants' do
      expect(router.find_handler('foo.bar.to_s')).to be_nil
      expect(router.find_handler('::foo::baz.to_s')).to be_nil
    end
  end
end

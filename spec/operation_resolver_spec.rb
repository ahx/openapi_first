# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

PET_EXPANDED_SPEC = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')

RSpec.describe OpenapiFirst::OperationResolver do
  describe '#call' do
    include Rack::Test::Methods

    module MyApi
      def self.find_pets(_params, _res); end

      def self.create_pet(_params, _res); end

      def self.update_pet(_params, _res); end

      def self.delete_pet(_params, res)
        res.status = 204
      end
    end

    let(:app) do
      Rack::Builder.new do
        use OpenapiFirst::Router,
            spec: PET_EXPANDED_SPEC,
            allow_unknown_operation: true
        use OpenapiFirst::RequestValidation,
            allow_unknown_query_parameters: true
        use OpenapiFirst::OperationResolver, namespace: MyApi
        run ->(_env) { Rack::Response.new('not found').finish }
      end
    end

    let(:request_body) do
      {
        'type' => 'people',
        'attributes' => {
          'name' => 'Oscar'
        }
      }
    end

    let(:response_body) do
      json_load(last_response.body, symbolize_keys: true)
    end

    it 'calls a method on the namespace module' do
      expect(MyApi).to receive(:find_pets)
      get '/pets'
    end

    it 'allows to set the response body as JSON via return value' do
      pets = [
        { name: 'Frido' }
      ]
      expect(MyApi).to receive(:find_pets) do |_params, _res|
        pets
      end

      get '/pets'
      expect(response_body).to eq(pets)
      expect(last_response[Rack::CONTENT_LENGTH]).to eq '18'
    end

    it 'allows to set the response body via res.write' do
      expected_body = 'Hi!'
      expect(MyApi).to receive(:find_pets) do |_req, res|
        res.write expected_body
        'ignored'
      end

      get '/pets'
      expect(last_response.body).to eq(expected_body)
      expect(last_response[Rack::CONTENT_LENGTH]).to eq '3'
    end

    it 'allows to modify the response' do
      pet = {
        type: 'pet',
        attributes: { name: 'Frido' }
      }
      expect(MyApi).to receive(:create_pet) do |_params, res|
        res.status = 201
        pet
      end

      header Rack::CONTENT_TYPE, 'application/json'
      post '/pets', json_dump(pet)
      expect(last_response.status).to eq(201)
      expect(response_body).to eq(pet)
    end

    describe 'response content-type' do
      it 'is automatically set as specified for the status code' do
        get '/pets'
        expect(last_response.status).to eq(200)
        expect(last_response[Rack::CONTENT_TYPE]).to eq 'application/json'
      end

      it 'can be set by the app' do
        expect(MyApi).to receive(:find_pets) do |_req, res|
          res.headers[Rack::CONTENT_TYPE] = 'application/xml'
          '<xml>'
        end
        get '/pets'
        expect(last_response.status).to eq(200)
        expect(last_response[Rack::CONTENT_TYPE]).to eq 'application/xml'
      end

      it 'defaults to nothing' do
        delete '/pets/1'
        expect(last_response.status).to eq(204)
        expect(last_response[Rack::CONTENT_TYPE]).to eq nil
      end
    end

    describe 'params' do
      it 'behaves like a hash' do
        params = OpenapiFirst::Params.new(:fake_env)

        params.merge!(existing: :value)
        params['existing'] = 'other_value'

        expect(params[:existing]).to eq :value
        expect(params['existing']).to eq 'other_value'
      end

      it 'returns nil on non-existant keys' do
        params = OpenapiFirst::Params.new(:fake_env)
        expect(params[:non_existing]).to be_nil
      end

      it 'has an env' do
        params = OpenapiFirst::Params.new(:fake_env)
        expect(params.env).to eq :fake_env
      end

      it 'has allowed query string parameters' do
        expected_params = {
          'tags' => ['foo']
        }
        expect(MyApi).to receive(:find_pets) do |params, _res|
          expect(params).to eq expected_params
        end

        get '/pets', 'tags[]' => 'foo', 'foo' => 'bar'
      end

      it 'has path parameters and request body' do
        pet = {
          'type' => 'pet',
          'attributes' => { 'name' => 'Frido' }
        }

        expected_params = {
          'id' => '1'
        }.merge(pet)

        expect(MyApi).to receive(:update_pet) do |params, _res|
          expect(params).to eq expected_params
        end

        header Rack::CONTENT_TYPE, 'application/json'
        patch '/pets/1', json_dump(pet)
      end
    end

    describe 'params.env' do
      it 'holds the Rack env' do
        expect(MyApi).to receive(:find_pets) do |params, _res|
          expect(params.env['PATH_INFO']).to eq '/pets'
          operation = params.env[OpenapiFirst::OPERATION]
          expect(operation.operation_id).to eq 'find_pets'
        end

        get '/pets'
      end
    end

    context 'when operation was not found' do
      it 'calls the next app' do
        header Rack::CONTENT_TYPE, 'application/json'
        get '/unknown'

        expect(last_response.body).to eq 'not found'
      end
    end

    context 'when run as rack app' do
      let(:app) do
        described_class.new(namespace: MyApi)
      end

      it 'works' do
        get '/pets'
        expect(last_response.status).to be 404
      end
    end
  end

  describe '#find_handler' do
    module MyApi
      module Things
        def self.some_class_method; end

        class Index
          def call; end
        end
      end
    end

    it 'finds some_method' do
      namespace = double(:some_method)
      resolver = described_class.new(namespace: namespace)
      expect(namespace).to receive(:some_method)
      resolver.find_handler('some_method').call
    end

    it 'finds things.some_method' do
      resolver = described_class.new(namespace: MyApi)
      expect(MyApi::Things).to receive(:some_class_method)
      resolver.find_handler('things.some_class_method').call
    end

    it 'finds things#index' do
      resolver = described_class.new(namespace: MyApi)
      expect_any_instance_of(MyApi::Things::Index).to receive(:call)
      resolver.find_handler('things#index').call
    end
  end
end

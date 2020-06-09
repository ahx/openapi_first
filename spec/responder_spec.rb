# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe OpenapiFirst::Responder do
  describe '#call' do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        spec = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')
        use OpenapiFirst::Router, spec: spec
        use OpenapiFirst::RequestValidation
        run OpenapiFirst::Responder.new(
          spec: spec,
          namespace: MyApi
        )
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

    before do
      namespace = Module.new do
        def self.find_pets(_params, _res); end

        def self.create_pet(_params, _res); end

        def self.update_pet(_params, _res); end

        def self.delete_pet(_params, res)
          res.status = 204
        end
      end

      stub_const('MyApi', namespace)
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

    it 'allows to set the response body as a string via return value' do
      pets = 'text'
      expect(MyApi).to receive(:find_pets) do |_params, _res|
        pets
      end

      get '/pets'
      expect(last_response.body).to eq(pets)
      expect(last_response[Rack::CONTENT_LENGTH]).to eq '4'
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

    describe 'when the handler method cannot be found' do
      let(:app) do
        Rack::Builder.new do
          spec = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')
          use OpenapiFirst::Router, spec: spec
          run OpenapiFirst::Responder.new(
            spec: spec,
            resolver: {},
            namespace: MyApi
          )
        end
      end

      it 'raises an error' do
        expect do
          get '/pets'
        end.to raise_error OpenapiFirst::NotImplementedError, 'Could not find handler for GET /pets (find_pets)'
      end
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
        expect(last_response.status).to eq(204), last_response.body
        expect(last_response[Rack::CONTENT_TYPE]).to eq nil
      end
    end

    describe 'params' do
      it 'uses INBOX from env' do
        expect(MyApi).to receive(:find_pets) do |params, _res|
          expect(params).to be params.env[OpenapiFirst::INBOX]
        end

        get '/pets', 'tags[]' => 'foo', 'foo' => 'bar'
      end

      it 'is an instance of Inbox' do
        expect(MyApi).to receive(:find_pets) do |params, _res|
          expect(params).to be_a OpenapiFirst::Inbox
        end

        get '/pets', 'tags[]' => 'foo', 'foo' => 'bar'
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
          'id' => 1
        }.merge(pet)

        expect(MyApi).to receive(:update_pet) do |params, _res|
          expect(params).to eq expected_params
        end

        header Rack::CONTENT_TYPE, 'application/json'
        patch '/pets/1', json_dump(pet)
        expect(last_response.status).to eq(200), last_response.body
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
  end
end

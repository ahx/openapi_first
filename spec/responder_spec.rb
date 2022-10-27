# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe OpenapiFirst::Responder do
  describe '#call' do
    include Rack::Test::Methods

    let(:app) do
      responder = OpenapiFirst::Responder.new(
        namespace: namespace
      )
      Rack::Builder.new do
        spec = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')
        use OpenapiFirst::Router, spec: spec
        use OpenapiFirst::RequestValidation
        use Rack::Lint
        run responder
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

    let(:namespace) do
      Module.new do
        def self.find_pets(_params, _res); end

        def self.create_pet(_params, _res); end

        def self.update_pet(_params, _res); end

        def self.delete_pet(_params, res)
          res.status = 204
        end
      end
    end

    it 'calls a method on the namespace module' do
      expect(namespace).to receive(:find_pets)
      get '/pets'
    end

    it 'allows to set the response body as JSON via return value' do
      pets = [
        { name: 'Frido' }
      ]
      expect(namespace).to receive(:find_pets) do |_params, _res|
        pets
      end

      get '/pets'
      expect(response_body).to eq(pets)
      expect(last_response[Rack::CONTENT_LENGTH]).to eq '18'
    end

    it 'allows to set the response body as a string via return value' do
      pets = 'text'
      expect(namespace).to receive(:find_pets) do |_params, _res|
        pets
      end

      get '/pets'
      expect(last_response.body).to eq(pets)
      expect(last_response[Rack::CONTENT_LENGTH]).to eq '4'
    end

    it 'allows to set the response body via res.write' do
      expected_body = 'Hi!'
      expect(namespace).to receive(:find_pets) do |_req, res|
        res.write expected_body
        'ignored'
      end

      get '/pets'
      expect(last_response.body).to eq(expected_body)
      expect(last_response[Rack::CONTENT_LENGTH]).to eq '3'
    end

    context 'with a custom resolver' do
      it 'finds the handler by passing the operation to the resolver' do
        spec = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')
        operation = spec.operations.find { |o| o.operation_id == 'find_pets' }
        handler = double(:call)
        resolver = double(:call)
        app = described_class.new(resolver: resolver)
        env = Rack::MockRequest.env_for('/pets')
        env[OpenapiFirst::OPERATION] = operation
        expect(resolver).to receive(:call).with(operation) { handler }
        expect(handler).to receive(:call)
        app.call(env)
      end
    end

    context 'with no operationId or x-handler defined' do
      it 'raises an error' do
        spec = OpenapiFirst.load('./spec/data/no-operation-name.yaml')
        operation = spec.operations.first
        app = described_class.new
        env = Rack::MockRequest.env_for('/pets')
        env[OpenapiFirst::OPERATION] = operation
        expect do
          app.call(env)
        end.to raise_error OpenapiFirst::HandlerNotFoundError,
                           "operationId or x-handler is missing in 'get /' so I cannot find a handler for this operation." # rubocop:disable Layout/LineLength
      end
    end

    context 'with x-handler' do
      it 'finds the handler based on x-handler field instead of operationId' do
        spec = OpenapiFirst.load('./spec/data/x-handler.yaml')
        operation = spec.operations.first
        handler = double(:call)
        app = described_class.new(resolver: proc { handler })
        env = Rack::MockRequest.env_for('/pets')
        env[OpenapiFirst::OPERATION] = operation
        expect(handler).to receive(:call)
        app.call(env)
      end

      it 'raises an error if it does not find the handler' do
        spec = OpenapiFirst.load('./spec/data/x-handler.yaml')
        operation = spec.operations.first
        resolver = proc {}
        app = described_class.new(resolver: resolver)
        env = Rack::MockRequest.env_for('/pets')
        env[OpenapiFirst::OPERATION] = operation
        expect do
          app.call(env)
        end.to raise_error OpenapiFirst::NotImplementedError, 'Could not find handler for GET / (things#index)'
      end
    end

    describe 'when the handler method cannot be found' do
      let(:app) do
        responder = OpenapiFirst::Responder.new(
          resolver: proc {},
          namespace: namespace
        )
        Rack::Builder.new do
          spec = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')
          use OpenapiFirst::Router, spec: spec
          run responder
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
      expect(namespace).to receive(:create_pet) do |_params, res|
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
        expect(namespace).to receive(:find_pets) do |_req, res|
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
        expect(namespace).to receive(:find_pets) do |params, _res|
          expect(params).to eq params.env[OpenapiFirst::INBOX]
        end

        get '/pets', 'tags[]' => 'foo', 'foo' => 'bar'
      end

      it 'is an instance of Inbox' do
        expect(namespace).to receive(:find_pets) do |params, _res|
          expect(params).to be_a OpenapiFirst::Inbox
        end

        get '/pets', 'tags[]' => 'foo', 'foo' => 'bar'
      end

      it 'has allowed query string parameters' do
        expected_params = {
          tags: ['foo']
        }
        expect(namespace).to receive(:find_pets) do |params, _res|
          expect(params).to eq expected_params
        end

        get '/pets', 'tags[]' => 'foo', 'foo' => 'bar'
      end

      it 'has path parameters and request body' do
        pet = {
          type: 'pet',
          attributes: { name: 'Frido' }
        }

        expected_params = {
          id: 1
        }.merge(pet)

        expect(namespace).to receive(:update_pet) do |params, _res|
          expect(params).to eq expected_params
        end

        header Rack::CONTENT_TYPE, 'application/json'
        patch '/pets/1', json_dump(pet)
        expect(last_response.status).to eq(200), last_response.body
      end
    end

    describe 'params.env' do
      it 'holds the Rack env' do
        expect(namespace).to receive(:find_pets) do |params, _res|
          expect(params.env['PATH_INFO']).to eq '/pets'
          operation = params.env[OpenapiFirst::OPERATION]
          expect(operation.operation_id).to eq 'find_pets'
        end

        get '/pets'
      end
    end
  end
end

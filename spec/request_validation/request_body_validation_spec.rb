# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Request body validation' do
  let(:path) do
    '/pets'
  end

  describe '#call' do
    include Rack::Test::Methods

    let(:raise_error_option) { false }

    let(:app) do
      raise_error = raise_error_option
      Rack::Builder.new do
        spec = OpenapiFirst.load('./spec/data/request-body-validation.yaml')
        use OpenapiFirst::RequestValidation, spec: spec, raise_error: raise_error
        run lambda { |_env|
          Rack::Response.new('hello', 200).finish
        }
      end
    end

    let(:request_body) do
      {
        type: 'pet',
        attributes: {
          name: 'Oscar'
        }
      }
    end

    let(:response_body) do
      json_load(last_response.body, symbolize_keys: true)
    end

    it 'works with stringio' do
      header Rack::CONTENT_TYPE, 'application/json'
      io = StringIO.new(json_dump(request_body))
      post path, io

      expect(last_response.status).to be 200
    end

    it 'works with % in request body' do
      request_body = {
        type: 'pet',
        attributes: {
          name: 'Oscar 100%'
        }
      }
      header Rack::CONTENT_TYPE, 'application/json'
      io = StringIO.new(json_dump(request_body))
      post path, io

      expect(last_response.status).to be 200
    end

    it 'succeeds if request body is valid' do
      header Rack::CONTENT_TYPE, 'application/json'
      post path, json_dump(request_body)

      expect(last_response.status).to be 200
    end

    it 'adds parsed request body to env' do
      header Rack::CONTENT_TYPE, 'application/json'
      post path, json_dump(request_body)

      expect(last_response.status).to be 200
      expect(last_request.env[OpenapiFirst::REQUEST_BODY]).to eq request_body
    end

    it 'updates INBOX' do
      header Rack::CONTENT_TYPE, 'application/json'
      post path, json_dump(request_body)

      expect(last_request.env[OpenapiFirst::INBOX]).to eq request_body
    end

    it 'returns 400 if request body is not valid' do
      request_body[:attributes][:name] = 43
      header Rack::CONTENT_TYPE, 'application/json'
      post path, json_dump(request_body)

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'should be a string'
      expect(error[:source][:pointer]).to eq '/attributes/name'
    end

    it 'returns 400 if required field is missing' do
      request_body[:attributes].delete(:name)
      header Rack::CONTENT_TYPE, 'application/json'
      post path, json_dump(request_body)

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'is missing required properties: name'
      expect(error[:source][:pointer]).to eq '/attributes'
    end

    it 'returns 400 if value is not defined in enum' do
      request_body[:type] = 'unknown-type'
      header Rack::CONTENT_TYPE, 'application/json'
      post path, json_dump(request_body)

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'value "unknown-type" is not defined in enum'
      expect(error[:source][:pointer]).to eq '/type'
      expect(error[:detail]).to eq 'value can be one of pet, plant'
    end

    it 'returns 400 if additional property is not allowed' do
      request_body[:attributes].update(foo: :bar)
      header Rack::CONTENT_TYPE, 'application/json'
      post path, json_dump(request_body)

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'unknown fields are not allowed'
      expect(error[:source][:pointer]).to eq '/attributes/foo'
    end

    it 'returns 400 if request body is invalid JSON' do
      header Rack::CONTENT_TYPE, 'application/json'
      post path, '{fo},'

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'Failed to parse body as JSON'
      expect(error[:detail]).to include "unexpected token at '{fo},'"
    end

    describe 'with default values' do
      before { header Rack::CONTENT_TYPE, 'application/json' }

      it 'adds the default value if value is missing' do
        params = {}
        post '/with-default-body-value', json_dump(params)
        expect(last_response.status).to eq(200)
        values = last_request.env[OpenapiFirst::INBOX]
        expect(values[:has_default]).to eq true
      end

      it 'still validates the value' do
        params = {
          has_default: 'not-a-boolean'
        }
        post '/with-default-body-value', json_dump(params)
        expect(last_response.status).to eq(400)
      end

      it 'accepts the given value if value is given' do
        params = { has_default: false }
        post '/with-default-body-value', json_dump(params)
        expect(last_response.status).to eq(200)
        values = last_request.env[OpenapiFirst::INBOX]
        expect(values[:has_default]).to eq false
      end
    end

    it 'returns 415 if required request body is missing' do
      header Rack::CONTENT_TYPE, 'application/json'
      post path

      expect(last_response.status).to be 415
    end

    it 'returns 415 if request content-type does not match' do
      header Rack::CONTENT_TYPE, 'application/xml'
      post path, '<xml />'

      expect(last_response.status).to be 415
      error = response_body[:errors][0]
      expect(error[:status]).to eq '415'
      expect(error[:title]).to eq 'Unsupported Media Type'
    end

    describe 'when operation does not specify request body' do
      it 'skips request body validation' do
        post '/without-request-body'

        expect(last_response.status).to be 200
        expect(last_response.body).to eq 'hello'
      end
    end

    describe 'when request body is empty and not required' do
      it 'skips request body validation' do
        header Rack::CONTENT_TYPE, 'application/json'
        patch '/pets/1'

        expect(last_response.status).to eq(200), last_response.body
        expect(last_response.body).to eq 'hello'
      end
    end

    describe 'with a required writeOnly field' do
      let(:app) do
        Rack::Builder.new do
          spec = OpenapiFirst.load('./spec/data/writeonly.yaml')
          use OpenapiFirst::Router, spec: spec, raise_error: true
          use OpenapiFirst::RequestValidation
          run lambda { |_env|
            Rack::Response.new('hello', 201).finish
          }
        end
      end

      it 'returns 400 if field is missing' do
        header Rack::CONTENT_TYPE, 'application/json'
        post '/test', json_dump({ name: 'Gunda' })
        expect(last_response.status).to eq(400), last_response.body
      end

      it 'passes validation if field in request body is valid' do
        header Rack::CONTENT_TYPE, 'application/json'
        post '/test', json_dump({ name: 'Gunda', password: 'admin' })
        expect(last_response.status).to eq(201), last_response.body
      end
    end

    describe 'with a readOnly required field' do
      let(:app) do
        Rack::Builder.new do
          spec = OpenapiFirst.load('./spec/data/readonly.yaml')
          use OpenapiFirst::Router, spec: spec, raise_error: true
          use OpenapiFirst::RequestValidation, raise_error: true
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end

      it 'fails if request includes readOnly field' do
        header Rack::CONTENT_TYPE, 'application/json'
        request_body = {
          name: 'foo',
          id: '123'
        }
        expect do
          post '/test', json_dump(request_body)
        end.to raise_error OpenapiFirst::RequestInvalidError, 'Request body invalid: /id appears in request, but is read-only' # rubocop:disable Layout/LineLength
      end
    end

    describe 'with a required nullable field' do
      let(:app) do
        Rack::Builder.new do
          spec = OpenapiFirst.load('./spec/data/nullable.yaml')
          use OpenapiFirst::Router, spec: spec, raise_error: true
          use OpenapiFirst::RequestValidation, raise_error: true
          run lambda { |_env|
            Rack::Response.new('hello', 201).finish
          }
        end
      end

      it 'fails if field is missing' do
        header Rack::CONTENT_TYPE, 'application/json'
        expect do
          post '/test', json_dump({})
        end.to raise_error OpenapiFirst::RequestInvalidError, 'Request body invalid: is missing required properties: name' # rubocop:disable Layout/LineLength
      end

      it 'succeeds if field is nil' do
        header Rack::CONTENT_TYPE, 'application/json'
        request_body = {
          name: nil
        }
        post '/test', json_dump(request_body)
        expect(last_response.status).to eq 201
      end
    end

    describe 'raise_error: true' do
      let(:raise_error_option) { true }

      it 'raises error if request body is not valid' do
        request_body[:attributes][:name] = 43
        header Rack::CONTENT_TYPE, 'application/json'
        expect do
          post path, json_dump(request_body)
        end.to raise_error OpenapiFirst::RequestInvalidError, 'Request body invalid: /attributes/name should be a string' # rubocop:disable Layout/LineLength
      end

      it 'raises error if required field is missing' do
        request_body[:attributes].delete(:name)
        header Rack::CONTENT_TYPE, 'application/json'
        expect do
          post path, json_dump(request_body)
        end.to raise_error OpenapiFirst::RequestInvalidError, 'Request body invalid: /attributes is missing required properties: name' # rubocop:disable Layout/LineLength
      end

      it 'raises error if request body is invalid JSON' do
        header Rack::CONTENT_TYPE, 'application/json'
        expect do
          post path, '{fo},'
        end.to raise_error OpenapiFirst::RequestInvalidError, 'Failed to parse body as JSON'
      end

      it 'raises error if request content-type does not match' do
        header Rack::CONTENT_TYPE, 'application/xml'
        expect do
          post path, '<xml />'
        end.to raise_error OpenapiFirst::RequestInvalidError, 'Unsupported Media Type'
      end
    end
  end
end

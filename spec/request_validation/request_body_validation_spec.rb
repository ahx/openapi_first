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
        spec = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')
        use OpenapiFirst::Router, spec: spec
        use OpenapiFirst::RequestValidation, raise_error: raise_error
        run lambda { |_env|
          Rack::Response.new('hello', 200).finish
        }
      end
    end

    let(:request_body) do
      {
        type: 'people',
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
        get '/pets'

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

      it 'skips validation of required readOnly fields for write requests' do
        header Rack::CONTENT_TYPE, 'application/json'
        request_body = {
          name: 'foo'
        }
        post '/test', json_dump(request_body)
        expect(last_response.status).to be 200
      end

      it 'removes readOnly fields from request bodies for write requests' do
        header Rack::CONTENT_TYPE, 'application/json'
        request_body = {
          id: 'ignoreme',
          name: 'foo'
        }
        post '/test', json_dump(request_body)

        expect(last_response.status).to be 200
        expected_req_body = { name: 'foo' }
        expect(last_request.env[OpenapiFirst::REQUEST_BODY]).to eq expected_req_body
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

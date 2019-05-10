# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first/router'
require 'openapi_first/request_body_validation'

PET_EXPANDED_SPEC = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')

RSpec.describe OpenapiFirst::RequestBodyValidation do
  let(:path) do
    '/pets'
  end

  describe '#call' do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use OpenapiFirst::Router, spec: PET_EXPANDED_SPEC,
                                  allow_unknown_operation: true
        use OpenapiFirst::RequestBodyValidation
        run lambda { |_env|
          Rack::Response.new('hello', 200)
        }
      end
    end

    let(:request_body) do
      {
        'name' => 'Oscar'
      }
    end

    let(:response_body) do
      json_load(last_response.body, symbolize_keys: true)
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

    it 'returns 400 if request body is not valid' do
      request_body[:name] = 43
      header Rack::CONTENT_TYPE, 'application/json'
      post path, json_dump(request_body)

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'is not valid'
      expect(error[:source][:parameter]).to eq 'name'
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

    describe 'when operation was not found' do
      it 'skips request body validation' do
        request_body[:name] = 43
        header Rack::CONTENT_TYPE, 'application/json'
        put path, json_dump(request_body)

        expect(last_response.status).to be 200
        expect(last_response.body).to eq 'hello'
      end
    end

    describe 'when request body is empty and not required' do
      it 'skips request body validation' do
        header Rack::CONTENT_TYPE, 'application/json'
        patch '/pets/1'

        expect(last_response.status).to be 200
        expect(last_response.body).to eq 'hello'
      end
    end
  end
end

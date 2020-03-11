# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

SEARCH_SPEC = OpenapiFirst.load('./spec/data/search.yaml')

RSpec.describe 'Parameter validation' do
  include Rack::Test::Methods

  let(:path) do
    '/search'
  end

  let(:app) do
    Rack::Builder.app do
      use OpenapiFirst::Router, spec: SEARCH_SPEC,
                                namespace: Web
      use OpenapiFirst::RequestValidation
      run lambda { |_env|
        Rack::Response.new('hello', 200).finish
      }
    end
  end

  before do
    stub_const('Web', double('Web', search: nil, info: nil))
  end

  describe '#call' do
    let(:params) do
      {
        'term' => 'Oscar'
      }
    end

    let(:response_body) do
      json_load(last_response.body, symbolize_keys: true)
    end

    it 'returns 400 if query parameter is missing' do
      params.delete('term')
      get path, params

      expect(last_response.status).to eq 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'is missing required properties: term'
    end

    it 'returns 400 if query parameter is not valid' do
      params[:birthdate] = 'not-a-date'
      get path, params

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'is not valid'
      expect(error[:source][:parameter]).to eq 'birthdate'
    end

    it 'returns 400 if query parameter does not match pattern' do
      params[:include] = 'foo,bar'
      get path, params

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'is not valid'
      expect(error[:detail]).to eq(
        "does not match pattern '(parents|children)+(,(parents|children))*'"
      )
      expect(error[:source][:parameter]).to eq 'include'
    end

    it 'adds filtered query parameters to env ' do
      get path, params

      expect(last_request.env[OpenapiFirst::PARAMS]).to eq params
    end

    it 'skips parameter validation if no parameters are defined' do
      get '/info', params

      puts last_response.body
      expect(last_response.status).to be 200
    end

    it 'succeeds if query parameter are valid' do
      get path, params

      expect(last_response.status).to be 200
    end

    it 'does not pass unknown query parameters to the handler' do
      get path, params.merge(foo: 'bar')

      expect(last_response.status).to eq 200
      expect(last_request.env[OpenapiFirst::PARAMS]).to eq params
    end

    describe 'type conversion' do
      let(:last_params) { last_request.env[OpenapiFirst::PARAMS] }

      it 'converts to integer' do
        get path, params.merge(limit: '100')

        expect(last_response.status).to eq(200), last_response.body
        expect(last_params['limit']).to eq 100

        get path, params.merge(limit: 'invalid')
        expect(last_response.status).to eq(400)

        get path, params.merge(limit: '0x23')
        expect(last_response.status).to eq(400)
      end

      it 'converts to float (number)' do
        get path, params.merge(weight: '1.5')

        expect(last_response.status).to eq(200), last_response.body
        expect(last_params['weight']).to eq 1.5

        get path, params.merge(limit: 'invalid')
        expect(last_response.status).to eq(400)

        get path, params.merge(limit: '0x23')
        expect(last_response.status).to eq(400)
      end

      it 'converts nested params' do
        get path, params.merge(filter: { id: '100', tag: 'foo' })

        expect(last_response.status).to eq(200), last_response.body
        expect(last_params['filter']['id']).to eq 100
      end
    end
  end
end

# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

SEARCH_SPEC = OpenapiFirst.load('./spec/data/search.yaml')

RSpec.describe 'Query parameter validation' do
  include Rack::Test::Methods

  let(:path) do
    '/search'
  end

  let(:app) do
    Rack::Builder.app do
      use OpenapiFirst::Router, spec: SEARCH_SPEC,
                                allow_unknown_operation: true
      use OpenapiFirst::RequestValidation
      run lambda { |_env|
        Rack::Response.new('hello', 200)
      }
    end
  end

  describe '#call' do
    let(:query_params) do
      {
        'term' => 'Oscar'
      }
    end

    let(:response_body) do
      json_load(last_response.body, symbolize_keys: true)
    end

    it 'returns 400 if query parameter is missing' do
      query_params.delete('term')
      get path, query_params

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'is missing required properties: term'
    end

    it 'returns 400 if query parameter is not valid' do
      query_params[:birthdate] = 'not-a-date'
      get path, query_params

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'is not valid'
      expect(error[:source][:parameter]).to eq 'birthdate'
    end

    it 'returns 400 if query parameter does not match pattern' do
      query_params[:include] = 'foo,bar'
      get path, query_params

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'is not valid'
      expect(error[:detail]).to eq(
        "does not match pattern '(parents|children)+(,(parents|children))*'"
      )
      expect(error[:source][:parameter]).to eq 'include'
    end

    it 'does not allow additional query parameters by default' do
      query_params.update(foo: 'bar')
      get path, query_params

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq('unknown fields are not allowed')
      expect(error[:source][:parameter]).to eq 'foo'
    end

    it 'adds filtered query parameters to env ' do
      get path, query_params

      expect(last_request.env[OpenapiFirst::QUERY_PARAMS]).to eq query_params
    end

    it 'skips parameter validation if operation was not found' do
      post path, query_params

      expect(last_response.status).to be 200
    end

    it 'skips parameter validation if no parameters are defined' do
      get '/info', query_params

      puts last_response.body
      expect(last_response.status).to be 200
    end

    it 'succeeds if query parameter are valid' do
      get path, query_params

      expect(last_response.status).to be 200
    end

    describe('allow_additional_parameters: true') do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::Router, spec: SEARCH_SPEC
          use OpenapiFirst::RequestValidation,
              allow_additional_parameters: true
          run lambda { |_env|
            Rack::Response.new('hello', 200)
          }
        end
      end

      it 'does allow additional query parameters by default' do
        query_params[:foo] = 'bar'
        get path, query_params

        expect(last_response.status).to be 200
      end

      it 'still adds filtered query parameters to env ' do
        get path, query_params.merge(foo: 'bar')

        expect(last_request.env[OpenapiFirst::QUERY_PARAMS]).to eq query_params
      end
    end
  end
end

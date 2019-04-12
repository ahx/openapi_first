# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first/request_parameter_validation'

RSpec.describe OpenapiFirst::RequestParameterValidation do
  API_SPEC = OpenapiFirst.load('./spec/data/openapi/search.yaml')

  App = Rack::Builder.new do
    use OpenapiFirst::RequestParameterValidation, spec: API_SPEC
    run lambda { |_env|
      Rack::Response.new('hello', 200)
    }
  end

  describe '#call' do
    include Rack::Test::Methods

    def app
      App
    end

    let(:query_params) do
      {
        q: 'Oscar'
      }
    end

    let(:response_body) do
      json_load(last_response.body, symbolize_keys: true)
    end

    let(:path) do
      '/search'
    end

    it 'returns 400 if query parameter is missing' do
      query_params.delete(:q)
      get path, query_params

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'is missing'
      expect(error[:source][:parameter]).to eq 'q'
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
      expect(error[:detail]).to eq "does not match pattern '(parents|children)+(,(parents|children))*'"
      expect(error[:source][:parameter]).to eq 'include'
    end

    it 'does not allow additional query parameters in strict mode' do
      query_params[:foo] = 'bar'
      get path, query_params

      expect(last_response.status).to be 400
    end

    it 'adds whitelisted query parameters to env in non strict mode' # do
    # query_params[:foo] = 'bar'
    # env = Rack::MockRequest.env_for(path, params: query_params)
    # app.call(env)

    # expect(env[OpenapiFirst::QUERY_PARAMS]).to be query_params
    # end

    it 'skips parameter validation if path was not found' do
      get '/foo'

      expect(last_response.status).to be 200
    end

    it 'skips parameter validation if method was not found' do
      post path, query_params

      expect(last_response.status).to be 200
    end

    it 'succeeds if query parameter are valid' do
      get path, query_params

      expect(last_response.status).to be 200
    end
  end

  describe '#query_parameter_schema' do
    let(:subject) do
      app = ->(_env) { Rack::Response(['hello'], 200) }
      described_class.new(app, spec: API_SPEC)
    end

    it 'returns the JSON Schema for the request' do
      expected_schema = {
        'properties' => {
          'birthdate' => {
            'format' => 'date',
            'type' => 'string'
          },
          'include' => {
            'type' => 'string',
            'pattern' => '(parents|children)+(,(parents|children))*'
          },
          'limit' => {
            'type' => 'integer',
            'format' => 'int32'
          },
          'q' => {
            'type' => 'string'
          }
        },
        'required' => [
          'q'
        ],
        'type' => 'object'
      }

      env = Rack::MockRequest.env_for('/search')
      request = Rack::Request.new(env)
      expect(subject.parameter_schema(request)).to eq expected_schema
    end
  end
end

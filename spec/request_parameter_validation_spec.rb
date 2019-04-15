# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first/request_parameter_validation'

RSpec.describe OpenapiFirst::RequestParameterValidation do
  API_SPEC = OpenapiFirst.load('./spec/data/openapi/search.yaml')

  describe '#call' do
    include Rack::Test::Methods

    let(:app) do
      Rack::Builder.new do
        use OpenapiFirst::RequestParameterValidation, spec: API_SPEC
        run lambda { |_env|
          Rack::Response.new('hello', 200)
        }
      end
    end

    let(:query_params) do
      {
        'term' => 'Oscar'
      }
    end

    let(:response_body) do
      json_load(last_response.body, symbolize_keys: true)
    end

    let(:path) do
      '/search'
    end

    it 'returns 400 if query parameter is missing' do
      query_params.delete('term')
      get path, query_params

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'is missing'
      expect(error[:source][:parameter]).to eq 'term'
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

    it 'does not allow additional query parameters by default' do
      query_params[:foo] = 'bar'
      get path, query_params

      expect(last_response.status).to be 400
    end

    it 'adds filtered query parameters to env ' do
      env = Rack::MockRequest.env_for(path, params: query_params)
      app.call(env)

      expect(env[OpenapiFirst::QUERY_PARAMS]).to eq query_params
    end

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

    describe('allow_additional_parameters: true') do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::RequestParameterValidation,
              spec: API_SPEC,
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
        env = Rack::MockRequest.env_for(path, params: query_params.merge(foo: 'bar'))
        app.call(env)

        expect(env[OpenapiFirst::QUERY_PARAMS]).to eq query_params
      end
    end
  end

  describe '#query_parameter_schema' do
    let(:subject) do
      app = ->(_env) { Rack::Response(['hello'], 200) }
      described_class.new(app, spec: API_SPEC)
    end

    let(:expected_schema) do
      {
        'type' => 'object',
        'required' => %w[
          term
        ],
        'additionalProperties' => false,
        'properties' => {
          'birthdate' => {
            'format' => 'date',
            'type' => 'string'
          },
          'filter' => {
            'type' => 'object',
            'required' => ['tag'],
            'properties' => {
              'tag' => {
                'type' => 'string'
              },
              'other' => {
                'type' => 'object'
              }
            }
          },
          'include' => {
            'type' => 'string',
            'pattern' => '(parents|children)+(,(parents|children))*'
          },
          'limit' => {
            'type' => 'integer',
            'format' => 'int32'
          },
          'term' => {
            'type' => 'string'
          }
        }
      }
    end

    it 'returns the JSON Schema for the request' do
      env = Rack::MockRequest.env_for('/search')
      request = Rack::Request.new(env)
      parameter_schema = subject.parameter_schema(request)
      expect(parameter_schema).to eq expected_schema
    end
  end
end

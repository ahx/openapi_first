# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Parameter validation' do
  include Rack::Test::Methods

  let(:path) do
    '/search'
  end

  let(:spec) { OpenapiFirst.load('./spec/data/search.yaml') }

  let(:raise_error_option) { false }

  let(:app) do
    oas = spec
    raise_error = raise_error_option
    Rack::Builder.app do
      use OpenapiFirst::Router, spec: oas
      use OpenapiFirst::RequestValidation, raise_error: raise_error
      run lambda { |_env|
        Rack::Response.new('hello', 200).finish
      }
    end
  end

  describe '#call' do
    let(:params) do
      {
        term: 'Oscar'
      }
    end

    let(:response_body) do
      json_load(last_response.body, symbolize_keys: true)
    end

    describe 'if router is not used' do
      let(:app) do
        Rack::Builder.app do
          use OpenapiFirst::RequestValidation
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end

      it 'raises an error' do
        expect do
          get path, params
        end.to raise_error RuntimeError, 'OpenapiFirst::Router missing in middleware stack. Did you forget adding OpenapiFirst::Router?' # rubocop:disable Layout/LineLength
      end
    end

    it 'returns 400 if query parameter is missing' do
      params.delete(:term)
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
      expect(error[:title]).to eq 'is not valid: "not-a-date"'
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

      expect(last_request.env[OpenapiFirst::PARAMETERS]).to eq params
    end

    it 'updates INBOX' do
      get path, params

      expect(last_request.env[OpenapiFirst::INBOX]).to eq params
    end

    it 'skips parameter validation if no parameters are defined' do
      get '/info', params

      expect(last_response.status).to be 200
    end

    it 'succeeds if query parameter are valid' do
      get path, params

      expect(last_response.status).to be 200
    end

    it 'does not pass unknown query parameters to the handler' do
      get path, params.merge(foo: 'bar')

      expect(last_response.status).to eq 200
      expect(last_request.env[OpenapiFirst::PARAMETERS]).to eq params
    end

    describe 'with array query parameters' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters-array.yaml') }

      describe 'with form style no explode parameters (default)' do
        it 'parses the array' do
          params = {
            strings: 'a,b,c',
            integers: '2,3,4'
          }
          get '/default-style', params
          expect(last_response.status).to eq(200), last_response.body
          parsed_parameters = last_request.env[OpenapiFirst::PARAMETERS]
          expect(parsed_parameters[:strings]).to eq %w[a b c]
          expect(parsed_parameters[:integers]).to eq [2, 3, 4]
        end

        it 'returns 400 if array maxItems is exceeded' do
          params = {
            integers: '2,3,4,5,6'
          }
          get '/default-style', params
          expect(last_response.status).to eq(400), last_response.body
        end
      end
    end

    describe 'with nested[param]' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters-flat.yaml') }

      let(:params) do
        {
          term: 'Oscar',
          filter: { tag: 'dogs', id: '1', other: 'things' }
        }
      end

      it 'returns 400 if nested[parameter] is missing' do
        params[:filter].delete(:tag)
        get path, params

        expect(last_response.status).to eq 400
        error = response_body[:errors][0]
        expect(error[:source][:parameter]).to eq 'filter'
        expect(error[:title]).to eq 'is missing required properties: tag'
      end

      it 'passes if query parameters are valid' do
        get path, params

        expect(last_response.status).to eq 200
      end
    end

    describe 'if raise_error: true' do
      let(:raise_error_option) { true }

      it 'raises an error if query parameter is missing' do
        params.delete(:term)
        message = 'Query parameter invalid: is missing required properties: term'
        expect do
          get path, params
        end.to raise_error OpenapiFirst::RequestInvalidError, message
      end

      it 'raises an error if query parameter is invalid' do
        params[:include] = 'foo,bar'
        message = 'Query parameter invalid: include is not valid'
        expect do
          get path, params
        end.to raise_error OpenapiFirst::RequestInvalidError, message
      end
    end

    describe 'type conversion' do
      def last_params
        last_request.env[OpenapiFirst::PARAMETERS]
      end

      it 'converts to integer' do
        get path, params.merge(limit: '100')

        expect(last_response.status).to eq(200), last_response.body
        expect(last_params[:limit]).to eq 100

        get path, params.merge(limit: 'invalid')
        expect(last_response.status).to eq(400)

        get path, params.merge(limit: '0x23')
        expect(last_response.status).to eq(400)
      end

      it 'converts to float (number)' do
        get path, params.merge(weight: '1.5')

        expect(last_response.status).to eq(200), last_response.body
        expect(last_params[:weight]).to eq 1.5

        get path, params.merge(limit: 'invalid')
        expect(last_response.status).to eq(400)

        get path, params.merge(limit: '0x23')
        expect(last_response.status).to eq(400)
      end

      it 'converts to boolean' do
        get path, params.merge(starred: 'true')
        expect(last_response.status).to eq(200), last_response.body
        expect(last_params[:starred]).to eq true

        get path, params.merge(starred: 'false')
        expect(last_response.status).to eq(200), last_response.body
        expect(last_params[:starred]).to eq false

        get path, params.merge(starred: 'wrong')
        expect(last_response.status).to eq(400)
        expect(last_params[:starred]).to eq 'wrong'
      end

      it 'converts nested params' do
        get path, params.merge(filter: { id: '100', tag: 'foo' })

        expect(last_response.status).to eq(200), last_response.body
        expect(last_params[:filter][:id]).to eq 100
      end
    end
  end
end

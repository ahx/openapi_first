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

  let(:spec) { OpenapiFirst.load('./spec/data/parameter-validation.yaml') }

  let(:raise_error_option) { false }

  let(:app) do
    oas = spec
    raise_error = raise_error_option
    Rack::Builder.app do
      use OpenapiFirst::RequestValidation, spec: oas, raise_error: raise_error
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

    let(:params_with_defaults) do
      {
        term: 'Oscar',
        limit: 10
      }
    end

    let(:response_body) do
      json_load(last_response.body, symbolize_keys: true)
    end

    it 'returns 400 if query parameter is missing' do
      params.delete(:term)
      get path, params

      expect(last_response.status).to eq 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'is missing required properties: term'
      expect(error[:source][:parameter]).to eq ''
    end

    it 'returns 400 if query parameter has not valid format' do
      params[:birthdate] = 'not-a-date'
      get path, params

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'has not a valid date format'
      expect(error[:source][:parameter]).to eq 'birthdate'
    end

    it 'returns 400 if query parameter has not valid date-time format' do
      params[:date_time] = '2013-12-11T01:01:01'
      get path, params

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'has not a valid date-time format'
      expect(error[:source][:parameter]).to eq 'date_time'
    end

    it 'returns 400 if query parameter is empty' do
      params[:birthdate] = ''
      get path, params

      expect(last_response.status).to be 400
      error = response_body[:errors][0]
      expect(error[:title]).to eq 'has not a valid date format'
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
      expect(last_request.env[OpenapiFirst::PARAMETERS]).to eq params_with_defaults
    end

    it 'updates INBOX' do
      get path, params

      expect(last_request.env[OpenapiFirst::INBOX]).to eq params_with_defaults
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
      expect(last_request.env[OpenapiFirst::PARAMETERS]).to eq params_with_defaults
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

        it 'parses nested array' do
          params = {
            nested: { integers: '2,3,4' }
          }
          get '/default-style', params
          expect(last_response.status).to eq(200), last_response.body
          parsed_parameters = last_request.env[OpenapiFirst::PARAMETERS]
          expect(parsed_parameters[:nested][:integers]).to eq [2, 3, 4]
        end

        it 'ignores empty query params' do
          get '/default-style'
          expect(last_response.status).to eq(200), last_response.body
          parsed_parameters = last_request.env[OpenapiFirst::PARAMETERS]
          expect(parsed_parameters[:strings]).to be_nil
        end

        it 'returns 400 if array maxItems is exceeded' do
          params = {
            integers: '2,3,4,5,6'
          }
          get '/default-style', params
          expect(last_response.status).to eq(400), last_response.body
        end

        it 'returns 400 if array item is invalid' do
          params = {
            integers: '2,foo,4'
          }
          get '/default-style', params
          expect(last_response.status).to eq(400)
          error = response_body[:errors][0]
          expect(error[:source][:parameter]).to eq 'integers/1'
          expect(error[:title]).to eq 'should be a integer'
        end
      end
    end

    describe 'with default values' do
      it 'adds the default value if parameter is missing' do
        params = {}
        get '/with-default-query-param', params
        expect(last_response.status).to eq(200)
        parsed_parameters = last_request.env[OpenapiFirst::PARAMETERS]
        expect(parsed_parameters[:has_default]).to eq true
      end

      it 'still validates the parameter' do
        params = {
          has_default: 'not-a-boolean'
        }
        get '/with-default-query-param', params
        expect(last_response.status).to eq(400)
      end

      it 'accepts the given value if parameter is given' do
        params = { has_default: false }
        get '/with-default-query-param', params
        expect(last_response.status).to eq(200)
        parsed_parameters = last_request.env[OpenapiFirst::PARAMETERS]
        expect(parsed_parameters[:has_default]).to eq false
      end
    end

    describe 'with nested[param]' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters-flat.yaml') }

      let(:params) do
        {
          term: 'Oscar',
          filter: { id: '1', other: 'things' }
        }
      end

      it 'returns 400 if nested[parameter] is missing' do
        params[:filter].delete(:id)
        get path, params

        expect(last_response.status).to eq 400
        error = response_body[:errors][0]
        expect(error[:source][:parameter]).to eq 'filter'
        expect(error[:title]).to eq 'is missing required properties: id'
      end

      it 'returns 400 if non-required array parameter is nil' do
        params[:filter][:tag] = nil
        get path, params
        expect(last_response.status).to eq 400
        error = response_body[:errors][0]
        expect(error[:title]).to eq 'is not valid: nil'
      end

      it 'returns 400 if non-required array parameter is empty' do
        get "#{path}?term=Oscar&filter[id]=1&filter[tag]=&filter[other]=things"
        expect(last_response.status).to eq 400
        error = response_body[:errors][0]
        expect(error[:title]).to eq 'is not valid: ""'
      end

      it 'passes if query parameters are valid' do
        get path, params

        expect(last_response.status).to eq 200
      end

      it 'returns 404 if path is unknown' do
        get '/fooo'
        expect(last_response.status).to eq(404), last_response.body
      end

      it 'works with URL encoded query parameter names' do
        get "#{path}?filter%5Btag%5D=dogs&filter%5Bid%5D=1&term=foo"

        expect(last_response.status).to eq(200), last_response.body
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

      it 'raises an error if path is unknown' do
        expect do
          get '/unknown'
        end.to raise_error OpenapiFirst::NotFoundError
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

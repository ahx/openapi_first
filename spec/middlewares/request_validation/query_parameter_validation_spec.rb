# frozen_string_literal: true

require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Query Parameter validation' do
  include Rack::Test::Methods

  let(:spec) { OpenapiFirst.load('spec/data/query-parameter-validation.yaml') }

  let(:raise_error_option) { false }

  let(:app) do
    oas = spec
    raise_error = raise_error_option
    Rack::Builder.app do
      use(OpenapiFirst::Middlewares::RequestValidation, spec: oas, raise_error:)
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

    let(:expected_params) do
      {
        'term' => 'Oscar',
        'limit' => 10
      }
    end

    let(:response_body) do
      json_load(last_response.body, symbolize_keys: true)
    end

    it 'returns 400 if query parameter is missing' do
      params.delete(:term)
      get '/search', params

      expect(last_response.status).to eq 400
    end

    it 'returns 400 if query parameter has not valid format' do
      params[:birthdate] = 'not-a-date'
      get '/search', params

      expect(last_response.status).to be 400
      response_body[:errors][0]
    end

    it 'returns 400 if query parameter has not valid date-time format' do
      params[:date_time] = '2013-12-11T01:01:01'
      get '/search', params

      expect(last_response.status).to be 400
    end

    it 'returns 400 if query parameter is empty' do
      params[:birthdate] = ''
      get '/search', params

      expect(last_response.status).to be 400
    end

    it 'returns 400 if query parameter does not match pattern' do
      params[:include] = 'foo,bar'
      get '/search', params

      expect(last_response.status).to be 400
      expect(response_body[:errors]).to eq [{ code: 'pattern',
                                              message:
                'string at `/include` does not match pattern: (parents|children)+(,(parents|children))*',
                                              parameter: 'include' }]
    end

    it 'adds parsed query parameters to env ' do
      get '/search', params
      expect(last_request.env[OpenapiFirst::REQUEST].params).to eq expected_params
    end

    it 'skips parameter validation if no parameters are defined' do
      get '/info', params

      expect(last_response.status).to be 200
    end

    it 'succeeds if query parameter are valid' do
      get '/search', params

      expect(last_response.status).to be 200
    end

    it 'does not pass unknown query parameters to the handler' do
      get '/search', params.merge(foo: 'bar')

      expect(last_response.status).to eq 200
      expect(last_request.env[OpenapiFirst::REQUEST].params).to eq expected_params
    end

    context 'with array query parameters' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters-array.yaml') }

      context 'with form style no explode parameters (default)' do
        it 'parses the array' do
          params = {
            strings: 'a,b,c',
            integers: '2,3,4'
          }
          get '/default-style', params
          expect(last_response.status).to eq(200), last_response.body
          parsed_parameters = last_request.env[OpenapiFirst::REQUEST].params
          expect(parsed_parameters['strings']).to eq %w[a b c]
          expect(parsed_parameters['integers']).to eq [2, 3, 4]
        end

        it 'parses nested array' do
          get '/default-style?nested[integers]=2,3,4'
          expect(last_response.status).to eq(200), last_response.body
          parsed_parameters = last_request.env[OpenapiFirst::REQUEST].params
          expect(parsed_parameters['nested[integers]']).to eq [2, 3, 4]
        end

        it 'ignores empty query params' do
          get '/default-style'
          expect(last_response.status).to eq(200), last_response.body
          parsed_parameters = last_request.env[OpenapiFirst::REQUEST].params
          expect(parsed_parameters['strings']).to be_nil
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
        end
      end
    end

    context 'with default values' do
      it 'adds the default value if parameter is missing' do
        params = {}
        get '/with-default-query-param', params
        expect(last_response.status).to eq(200)
        parsed_parameters = last_request.env[OpenapiFirst::REQUEST].params
        expect(parsed_parameters['has_default']).to eq true
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
        parsed_parameters = last_request.env[OpenapiFirst::REQUEST].params
        expect(parsed_parameters['has_default']).to eq false
      end
    end

    context 'with nested[param]' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters-flat.yaml') }

      let(:params) do
        {
          'term' => 'Oscar',
          'filter[id]' => '1',
          'filter[other]' => 'things'
        }
      end

      it 'returns 400 if nested[parameter] is missing' do
        params.delete 'filter[id]'
        get '/search', params

        expect(last_response.status).to eq 400
      end

      it 'returns 400 if non-required array parameter is nil' do
        params['filter[tag]'] = nil
        get '/search', params
        expect(last_response.status).to eq 400
      end

      it 'returns 400 if non-required array parameter is empty' do
        get '/search?term=Oscar&filter[id]=1&filter[tag]=&filter[other]=things'
        expect(last_response.status).to eq 400
      end

      it 'passes if query parameters are valid' do
        get '/search', params

        expect(last_response.status).to eq(200), last_response.body
      end

      it 'returns 404 if path is unknown' do
        get '/fooo'
        expect(last_response.status).to eq(404), last_response.body
      end

      it 'works with URL encoded query parameter names' do
        get '/search?filter%5Btag%5D=dogs&filter%5Bid%5D=1&term=foo'

        expect(last_response.status).to eq(200), last_response.body
      end
    end

    describe 'if raise_error: true' do
      let(:raise_error_option) { true }

      it 'raises an error if query parameter is missing' do
        params.delete(:term)
        message = 'Query parameter is invalid: object at root is missing required properties: term'
        expect do
          get '/search', params
        end.to raise_error OpenapiFirst::RequestInvalidError, message
      end

      it 'raises an error if query parameter is invalid' do
        params[:include] = 'foo,bar'
        message = %r{Query parameter is invalid: string at `/include` does not match pattern}
        expect do
          get '/search', params
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
        last_request.env[OpenapiFirst::REQUEST].params
      end

      it 'converts to integer' do
        get '/search', params.merge(limit: '100')

        expect(last_response.status).to eq(200), last_response.body
        expect(last_params['limit']).to eq 100

        get '/search', params.merge(limit: 'invalid')
        expect(last_response.status).to eq(400)

        get '/search', params.merge(limit: '0x23')
        expect(last_response.status).to eq(400), last_response.body
      end

      it 'converts to float (number)' do
        get '/search', params.merge(weight: '1.5')

        expect(last_response.status).to eq(200), last_response.body
        expect(last_params['weight']).to eq 1.5

        get '/search', params.merge(limit: 'invalid')
        expect(last_response.status).to eq(400)

        get '/search', params.merge(limit: '0x23')
        expect(last_response.status).to eq(400)
      end

      it 'converts to boolean' do
        get '/search', { 'starred' => 'true', 'term' => 'search' }
        expect(last_response.status).to eq(200), last_response.body
        expect(last_params['starred']).to eq true

        get '/search', { 'starred' => 'false', 'term' => 'search' }
        expect(last_response.status).to eq(200), last_response.body
        expect(last_params['starred']).to eq false

        get '/search', { 'starred' => 'wrong', 'term' => 'search' }
        expect(last_response.status).to eq(400)
      end

      it 'works with symbol and string keys in test' do
        get '/search', { starred: 'true', term: 'search' }
        expect(last_response.status).to eq(200), last_response.body

        get '/search', { 'starred' => 'false', 'term' => 'search' }
        expect(last_response.status).to eq(200), last_response.body
      end

      it 'converts nested params' do
        get '/search', params.merge(filter: { id: '100', tag: 'foo' })

        expect(last_response.status).to eq(200), last_response.body
        expect(last_params.dig('filter', 'id')).to eq 100
      end
    end
  end
end

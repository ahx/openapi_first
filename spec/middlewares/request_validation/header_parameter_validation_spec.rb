# frozen_string_literal: true

require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Header Parameter validation' do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.app do
      use OpenapiFirst::Middlewares::RequestValidation,
          spec: File.expand_path('spec/data/header-parameter-validation.yaml')
      run lambda { |_env|
        Rack::Response.new('hello', 200).finish
      }
    end
  end

  describe '#call' do
    it 'returns 400 if header parameter is invalid' do
      header 'Accept-Version', 'not-an-integer'
      get '/pets'
      expect(last_response.status).to eq 400
    end

    it 'accepts a valid header parameter' do
      header 'Accept-Version', '1'
      get '/pets'

      expect(last_response.status).to eq 200
    end

    it 'succeeds if header parameter is valid' do
      header 'Accept-Version', '1'
      get '/pets'
      expect(last_response.status).to be 200
    end

    it 'adds the converted header parameter to env ' do
      header 'Accept-Version', '1'
      get '/pets'
      expect(last_request.env[OpenapiFirst::REQUEST].parsed_headers['Accept-Version']).to eq 1
    end

    context 'when raising' do
      let(:app) do
        Rack::Builder.app do
          spec_file = File.expand_path('spec/data/header-parameter-validation.yaml')
          use OpenapiFirst::Middlewares::RequestValidation, raise_error: true,
                                                            spec: spec_file
          run ->(_) {}
        end
      end

      it 'returns 400 if header parameter is invalid' do
        header 'Accept-Version', 'not-an-integer'
        expect do
          get '/pets'
        end.to raise_error OpenapiFirst::RequestInvalidError,
                           'Request header is invalid: value at `/Accept-Version` is not an integer'
      end
    end
  end
end

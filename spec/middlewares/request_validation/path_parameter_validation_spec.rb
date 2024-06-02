# frozen_string_literal: true

require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Path Parameter validation' do
  include Rack::Test::Methods

  let(:raise_error_option) { false }

  let(:app) do
    raise_error = raise_error_option
    Rack::Builder.app do
      use OpenapiFirst::Middlewares::RequestValidation, {
        spec: File.expand_path('spec/data/path-parameter-validation.yaml'),
        raise_error:
      }
      run lambda { |_env|
        Rack::Response.new('hello', 200).finish
      }
    end
  end

  describe '#call' do
    it 'returns 400 if path parameter is invalid' do
      get '/pets/not-an-integer'

      expect(last_response.status).to eq 400
    end

    it 'adds the converted path parameter to env' do
      get '/pets/42'
      expect(last_request.env[OpenapiFirst::REQUEST].parsed_path_parameters['petId']).to eq 42
    end

    context 'with valid parameters' do
      it 'succeeds for valid integer' do
        get '/pets/42'
        expect(last_response.status).to eq(200)
      end

      it 'succeeds for valid string' do
        get '/users/joe'
        expect(last_response.status).to eq(200)
      end

      it 'succeds for string with special characters' do
        get '/users/joe!doe'
        expect(last_response.status).to eq(200)
      end
    end

    it 'returns 404 if path parameter is empty' do
      get '/pets//'
      expect(last_response.status).to be 404
    end

    context 'when raise_error: true' do
      let(:raise_error_option) { true }

      it 'raises an error if query parameter is missing' do
        message = 'Path segment is invalid: value at `/petId` is not an integer'
        expect do
          get '/pets/not-an-integer'
        end.to raise_error OpenapiFirst::RequestInvalidError, message
      end
    end
  end
end

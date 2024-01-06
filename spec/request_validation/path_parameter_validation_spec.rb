# frozen_string_literal: true

require_relative '../spec_helper'
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
        spec: File.expand_path('../data/path-parameter-validation.yaml', __dir__),
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

    it 'adds the converted path parameter to env ' do
      get '/pets/42'
      expect(last_request.env[OpenapiFirst::REQUEST].params['petId']).to eq 42
    end

    it 'succeeds if path parameter are valid' do
      get '/pets/42'
      expect(last_response.status).to be 200
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

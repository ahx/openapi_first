# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Header Parameter validation' do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.app do
      use OpenapiFirst::RequestValidation, spec: File.expand_path('../data/header-parameter-validation.yaml', __dir__)
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
      error = json_load(last_response.body, symbolize_keys: true)[:errors][0]
      expect(error[:title]).to eq 'should be a integer'
      expect(error[:source][:header]).to eq 'Accept-Version'
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
      expect(last_request.env[OpenapiFirst::HEADER_PARAMS]['Accept-Version']).to eq 1
    end

    describe 'when raising' do
      let(:app) do
        Rack::Builder.app do
          spec_file = File.expand_path('../data/header-parameter-validation.yaml', __dir__)
          use OpenapiFirst::RequestValidation, raise_error: true,
                                               spec: spec_file
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end

      it 'returns 400 if header parameter is invalid' do
        header 'Accept-Version', 'not-an-integer'
        expect do
          get '/pets'
        end.to raise_error OpenapiFirst::RequestInvalidError,
                           'Header parameter invalid: Accept-Version should be a integer'
      end
    end
  end
end

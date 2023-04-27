# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Path Parameter validation' do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.app do
      use OpenapiFirst::RequestValidation, spec: File.expand_path('../data/path-parameter-validation.yaml', __dir__)
      run lambda { |_env|
        Rack::Response.new('hello', 200).finish
      }
    end
  end

  describe '#call' do
    it 'returns 400 if path parameter is invalid' do
      get '/pets/not-an-integer'

      expect(last_response.status).to eq 400
      error = json_load(last_response.body, symbolize_keys: true)[:errors][0]
      expect(error[:title]).to eq 'should be a integer'
      expect(error[:source][:parameter]).to eq 'petId'
    end

    it 'adds the converted path parameter to env ' do
      get '/pets/42'
      expect(last_request.env[OpenapiFirst::PARAMS]['petId']).to eq 42
    end

    it 'succeeds if path parameter are valid' do
      get '/pets/42'
      expect(last_response.status).to be 200
    end

    it 'returns 404 if path parameter is empty' do
      get '/pets//'
      expect(last_response.status).to be 404
    end
  end
end

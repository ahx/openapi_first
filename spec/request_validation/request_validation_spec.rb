# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Request validation' do
  include Rack::Test::Methods
  let(:app) do
    Rack::Builder.app do
      use OpenapiFirst::RequestValidation, spec: './spec/data/parameters.yaml', raise_error: true
      run lambda { |_env|
        Rack::Response.new('hello', 200).finish
      }
    end
  end

  describe '#call' do
    it 'adds merged query and path parameters to env ' do
      get '/stuff/12?version=1'
      expected_params = { 'version' => 1, 'id' => 12 }
      expect(last_request.env[OpenapiFirst::PARAMS]).to eq expected_params
    end

    it 'prioritizes path over query params' do
      get '/same-name-params/12?id=1'
      expected_params = { 'id' => 12 }
      expect(last_request.env[OpenapiFirst::PARAMS]).to eq expected_params
    end
  end
end

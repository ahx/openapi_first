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

  context 'with custom error_response option' do
    let(:app) do
      custom_class = Class.new(OpenapiFirst::ErrorResponse) do
        def body = 'custom error body'
        def content_type = 'text/plain'
        def status = 409
      end
      Rack::Builder.app do
        use OpenapiFirst::RequestValidation, spec: './spec/data/request-body-validation.yaml',
                                             error_response: custom_class
        run lambda { |_env|
          Rack::Response.new('hello', 200).finish
        }
      end
    end

    it 'uses the custom error response' do
      post '/pets'
      expect(last_response.status).to eq 409
      expect(last_response.content_type).to eq 'text/plain'
      expect(last_response.body).to eq 'custom error body'
    end
  end

  context 'with :default error_response option' do
    let(:app) do
      Rack::Builder.app do
        use OpenapiFirst::RequestValidation, spec: './spec/data/request-body-validation.yaml', error_response: :default
        run lambda { |_env|
          Rack::Response.new('hello', 200).finish
        }
      end
    end

    it 'returns 400' do
      header 'Content-Type', 'application/json'
      post '/pets'
      expect(last_response.status).to eq 400
    end
  end
end

# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe OpenapiFirst::Middlewares::ResponseValidation do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.app do
      use(OpenapiFirst::Middlewares::ResponseValidation, spec: File.expand_path('../data/petstore.yaml', __dir__))
      run lambda { |_env|
        Rack::Response.new('[]', 200, { 'Content-Type' => 'application/json' }).finish
      }
    end
  end

  context 'when response is valid' do
    it 'returns 200' do
      get '/pets'

      expect(last_response.status).to eq 200
    end

    it 'adds request to env ' do
      get '/pets'
      expect(last_request.env[OpenapiFirst::REQUEST]).to be_a OpenapiFirst::RuntimeRequest
    end
  end

  context 'when response is invalid' do
    let(:app) do
      Rack::Builder.new.tap do |builder|
        builder.use(described_class, spec: File.expand_path('../data/petstore.yaml', __dir__))
        builder.run lambda { |_env|
          Rack::Response.new('{"foo": "bar"}', 200, { 'Content-Type' => 'application/json' }).finish
        }
      end.to_app
    end

    it 'raises an error' do
      expect do
        get '/pets'
      end.to raise_error OpenapiFirst::ResponseInvalidError, 'Response body is invalid: value at root is not an array'
    end
  end

  context 'when response is not valid JSON' do
    let(:app) do
      Rack::Builder.new.tap do |builder|
        builder.use(described_class, spec: File.expand_path('../data/petstore.yaml', __dir__))
        builder.run lambda { |_env|
          Rack::Response.new('{boofar}', 200, { 'Content-Type' => 'application/json' }).finish
        }
      end.to_app
    end

    it 'raises an error' do
      expect do
        get '/pets'
      end.to raise_error OpenapiFirst::ResponseInvalidError,
                         'Response body is invalid: Failed to parse response body as JSON'
    end
  end

  context 'when path is not found' do
    it 'ignores the request' do
      get '/unknown'
      expect(last_response.status).to eq 200
    end
  end
end

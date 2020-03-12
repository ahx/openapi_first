# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first/coverage'

RSpec.describe OpenapiFirst::Coverage do
  include Rack::Test::Methods

  let(:spec) do
    spec_path = './spec/data/petstore.yaml'
    OpenapiFirst.load(spec_path)
  end

  let(:namespace) do
    double(show_pet_by_id: 'hello')
  end

  let(:app) do
    described_class.new(OpenapiFirst.app(spec, namespace: namespace), spec)
  end

  describe '#to_be_called' do
    it 'starts with all endpoints' do
      expected_endpoints = %w[/pets#get /pets#post /pets/{petId}#get]
      expect(app.to_be_called).to eq  expected_endpoints
    end

    it 'removes an endpoint after it was called' do
      expected_endpoints = %w[/pets#get /pets#post]
      get '/pets/1'

      expect(app.to_be_called).to eq expected_endpoints
      expect(last_response.body).to eq 'hello' # make we called the original app
    end
  end
end

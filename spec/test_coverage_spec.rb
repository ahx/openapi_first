require_relative 'spec_helper'
require 'rack'

RSpec.describe OpenapiFirst::TestCoverage do
  let(:spec) do
    spec_path = './spec/data/openapi/petstore.yaml'
    OpenapiFirst.load(spec_path)
  end

  let(:subject) do
    app = ->(_env) { Rack::Response.new('hello') }
    described_class.new(app, spec)
  end

  describe '#to_be_called' do
    it 'starts with all endpoints' do
      expected_endpoints = %w[/pets#get /pets#post /pets/{petId}#get]
      expect(subject.to_be_called).to eq  expected_endpoints
    end

    it 'removes an endpoint after it was called' do
      expected_endpoints = %w[/pets#get /pets#post]
      response = Rack::MockRequest.new(subject).get('/pets/1')
      expect(subject.to_be_called).to eq expected_endpoints
      expect(response.body).to eq 'hello' # make we called the original app
    end

    it 'allows paths unknown to the spec' do
      response = Rack::MockRequest.new(subject).get('/hello')
      expect(response.status).to eq 200
    end
  end
end

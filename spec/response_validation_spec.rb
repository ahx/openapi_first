# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe OpenapiFirst::ResponseValidation do
  include Rack::Test::Methods

  let(:app) do
    res = response
    Rack::Builder.app do
      spec = OpenapiFirst.load('./spec/data/petstore.yaml')
      use OpenapiFirst::Router, spec: spec
      use OpenapiFirst::ResponseValidation
      run ->(_env) { res.finish }
    end
  end

  let(:response_body) { json_dump([{ id: 42, name: 'hans' }]) }
  let(:status) { 200 }
  let(:headers) do
    { Rack::CONTENT_TYPE => 'application/json', 'X-HEAD' => '/api/next-page' }
  end
  let(:response) { Rack::Response.new(response_body, status, headers) }
  let(:path) { '/pets' }

  describe 'with a valid response' do
    it 'returns no errors' do
      get path

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq response_body
    end
  end

  describe 'unknown path' do
    let(:path) { '/unknown' }

    specify do
      get path
      expect(last_response.status).to eq 404
    end
  end

  describe 'no operation found' do
    let(:app) do
      Rack::Builder.app do
        use OpenapiFirst::ResponseValidation
        run ->(_env) { [200, {}, ''] }
      end
    end

    specify do
      get '/unknown'
      expect(last_response.status).to eq 200
    end
  end

  describe 'unknown status' do
    let(:status) { 407 }

    specify do
      expect do
        get '/pets/42'
      end.to raise_error OpenapiFirst::ResponseCodeNotFoundError
    end
  end

  describe 'response body invalid' do
    let(:response_body) do
      json_dump([
                  { name: 'hans' },
                  { id: '2', name: 'Voldemort' }
                ])
    end

    specify do
      message = [
        'is missing required properties: id at /0',
        'should be a integer at /1/id'
      ].join(', ')
      expect do
        get '/pets/42'
      end.to raise_error OpenapiFirst::ResponseBodyInvalidError, message
    end
  end

  describe 'unknown content-type' do
  end
end

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
      run lambda { |_env| res.finish }
    end
  end

  let(:response_body) { json_dump([{ id: 42, name: 'hans' }]) }
  let(:status) { 200 }
  let(:headers) { { 'X-HEAD' => '/api/next-page' } }
  let(:response) { Rack::MockResponse.new(status, headers, response_body) }
  let(:path) { '/pets'}

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
      expect(last_response.status).to eq 500
    end
  end

  describe 'no operation found' do
    let(:app) do
      Rack::Builder.app do
        use OpenapiFirst::ResponseValidation
        run lambda { |_env| [200, {}, ''] }
      end
    end

    specify do
      get '/unknown'
      expect(last_response.status).to eq 500
    end
  end

  describe 'unknown status' do
    let(:status) { 407 }

    specify do
      get path
      expect(last_response.status).to eq 500
    end
  end

  describe 'missing field in response body' do
    let(:response_body) do
      json_dump([
        { name: 'hans' },
        { id: 2, name: 'Voldemort' }
      ])
    end

    specify do
      get path
      expect(last_response.status).to eq 500
    end
  end

  describe 'missing header'
end

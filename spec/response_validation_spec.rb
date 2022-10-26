# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe OpenapiFirst::ResponseValidation do
  include Rack::Test::Methods

  let(:app) do
    res = response
    definition = spec
    Rack::Builder.app do
      use OpenapiFirst::ResponseValidation, spec: definition
      run ->(_env) { res.finish }
    end
  end

  let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }
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

  describe 'without content-type header' do
    let(:headers) do
      { 'X-HEAD' => '/api/next-page' }
    end

    it 'returns an error' do
      expect do
        get path
      end.to raise_error OpenapiFirst::ResponseInvalid, "Response has no content-type for 'GET /pets (listPets)'"
    end
  end

  describe 'with 204 no content response' do
    let(:spec) { OpenapiFirst.load('./spec/data/no-content.yaml') }
    let(:status) { 204 }

    let(:headers) do
      { 'X-HEAD' => '/api/next-page' }
    end

    it 'does not check the content or content-type' do
      delete '/pets/12'
      expect(last_response.status).to eq 204
    end
  end

  describe 'operation does not specify content-type' do
    let(:spec) { OpenapiFirst.load('./spec/data/no-content.yaml') }
    let(:status) { 423 }

    describe 'with any content-type' do
      let(:headers) do
        { Rack::CONTENT_TYPE => 'application/hal+json' }
      end

      it 'passes' do
        get '/pets/12'
        expect(last_response.status).to eq status
      end
    end

    describe 'with an empty content-type' do
      let(:headers) do
        { Rack::CONTENT_TYPE => nil }
      end

      it 'allows an empty content-type' do
        get '/pets/12'
        expect(last_response.status).to eq status
      end
    end
  end

  describe 'no operation found' do
    let(:app) do
      definition = spec
      Rack::Builder.app do
        use OpenapiFirst::ResponseValidation, spec: definition
        run ->(_env) { [200, {}, ''] }
      end
    end

    specify do
      env = { OpenapiFirst::OPERATION => nil }
      response = app.call(env)
      expect(response[0]).to eq 200
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

  describe 'with a XX wildcard response status' do
    let(:spec) { OpenapiFirst.load('./spec/data/response-code-wildcard.yaml') }
    let(:response_body) { {} }

    context 'when 4XX (upcase) is expected and 404 is sent' do
      let(:status) { 404 }

      it 'does not raise an error' do
        post '/test', json_dump({})
        expect(last_response.status).to eq 404
      end
    end

    context 'when 2xx (downcase, non-default) is expected and 205 is sent' do
      let(:status) { 205 }

      it 'does not raise an error' do
        post '/test', json_dump({})
        expect(last_response.status).to eq 205
      end
    end

    context 'when 4xx is expected and 302 is sent' do
      let(:status) { 302 }

      it 'finds the "default" response and raises an error' do
        expect do
          post '/test', json_dump({})
        end.to raise_error OpenapiFirst::ResponseBodyInvalidError
      end
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
        "property '/0' is missing required keys: id",
        "property '/1/id' is not of type: integer"
      ].join(', ')
      expect do
        get '/pets/42'
      end.to raise_error OpenapiFirst::ResponseBodyInvalidError, message
    end
  end

  describe 'with a writeOnly field' do
    let(:spec) { OpenapiFirst.load('./spec/data/writeonly.yaml') }
    let(:status) { 201 }

    context 'when field is sent in the response body' do
      let(:response_body) do
        json_dump({ name: 'hans', password: 'admin' })
      end

      it 'raises an error' do
        message = 'Write-only field appears in response: /password'
        expect do
          post '/test', json_dump({ name: 'hans', password: 'admin' })
        end.to raise_error OpenapiFirst::ResponseBodyInvalidError, message
      end
    end
  end

  describe 'with a required readOnly field' do
    let(:spec) { OpenapiFirst.load('./spec/data/readonly.yaml') }

    let(:response_body) do
      json_dump({ name: 'hans' })
    end

    it 'raises an error if the readOnly field is missing' do
      message = 'root is missing required keys: id'
      expect do
        get '/test/42'
      end.to raise_error OpenapiFirst::ResponseBodyInvalidError, message
    end

    describe 'when the readOnly field is valid' do
      let(:response_body) do
        json_dump({ id: '42', name: 'hans' })
      end

      it 'does not raise an error' do
        get '/test/42'
        expect(last_response.status).to eq 200
      end
    end
  end

  describe 'with a required nullable field' do
    let(:spec) { OpenapiFirst.load('./spec/data/nullable.yaml') }

    describe 'when the field is missing' do
      let(:response_body) do
        json_dump({})
      end

      it 'raises an error' do
        message = 'root is missing required keys: name'
        expect do
          get '/test'
        end.to raise_error OpenapiFirst::ResponseBodyInvalidError, message
      end
    end

    describe 'when the field is nil' do
      let(:response_body) do
        json_dump({ name: nil })
      end

      it 'does not raise an error' do
        get '/test'
        expect(last_response.status).to eq 200
      end
    end
  end
end

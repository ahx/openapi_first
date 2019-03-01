require_relative 'spec_helper'
require 'rack'

RSpec.describe OpenapiFirst::ResponseValidator do
  let(:spec) do
    spec_path = './spec/openapi/petstore.yaml'
    OpenapiFirst.load(spec_path)
  end

  let(:subject) do
    described_class.new(spec)
  end

  let(:request) do
    env = Rack::MockRequest.env_for('/pets')
    Rack::Request.new(env)
  end

  let(:headers) { { Rack::CONTENT_TYPE => 'application/json' } }

  describe 'valid response' do
    it 'returns true' do
      response_body = JSON.dump([{ id: 42, name: 'hans' }, { id: 2, name: 'Voldemort' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors).to be_empty
    end

    it 'returns true on additional, not required properties' do
      response_body = JSON.dump([{ id: 42, name: 'hans', something: 'else' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors).to be_empty
    end
  end

  describe 'invalid response' do
    it 'fails on unknown http method' do
      request = begin
        env = Rack::MockRequest.env_for('/pets', method: 'PATCH')
        Rack::Request.new(env)
      end
      response_body = JSON.dump([{ id: 'string', name: 'hans' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      expect { subject.validate(request, response) }.to raise_error(
        StandardError,
        'So such endpoint exists' # TODO: PR on https://github.com/Nexmo/oas_parser/issues/17
      )
    end

    it 'fails on unknown status' do
      response_body = JSON.dump([{ id: 2, name: 'Voldemort' }])
      response = Rack::MockResponse.new(201, headers, response_body)
      expect { subject.validate(request, response) }.to raise_error(
        StandardError,
        'So such response exists' # TODO: PR on https://github.com/Nexmo/oas_parser/issues/17
      )
    end

    it 'fails on wrong content type' do
      response_body = JSON.dump([{ id: 2, name: 'Voldemort' }])
      headers = { Rack::CONTENT_TYPE => 'application/xml' }
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result).to eq(false)
    end

    it 'fails on missing property' do
      response_body = JSON.dump([{ id: 42 }, { id: 2, name: 'Voldemort' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors).to eq(
        [
          {
            'data' => { 'id' => 42 },
            'data_pointer' => '/0',
            'schema' => {
              'properties' => {
                'id' => { 'format' => 'int64', 'type' => 'integer' },
                'name' => { 'type' => 'string' },
                'tag' => { 'type' => 'string' }
              },
              'required' => %w[id name]
            },
            'schema_pointer' => '/items',
            'type' => 'required'
          }
        ]
      )
    end

    it 'fails on wrong property type' do
      response_body = JSON.dump([{ id: 'string', name: 'hans' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors).to eq(
        [
          {
            'data' => 'string',
            'data_pointer' => '/0/id',
            'schema' => { 'format' => 'int64', 'type' => 'integer' },
            'schema_pointer' => '/items/properties/id',
            'type' => 'integer'
          }
        ]
      )
    end
  end
end

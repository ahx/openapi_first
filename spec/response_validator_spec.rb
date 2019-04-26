require_relative 'spec_helper'
require 'rack'
require 'openapi_first/response_validator'

RSpec.describe OpenapiFirst::ResponseValidator do
  let(:spec) do
    spec_path = './spec/data/petstore.yaml'
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
    it 'returns no errors' do
      response_body = json_dump([{ id: 42, name: 'hans' }, { id: 2, name: 'Voldemort' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors?).to be false
      expect(result.errors).to be_empty
    end

    it 'falls back to the default' do
      response_body = JSON.dump(code: 422, message: 'Not good!')
      response = Rack::MockResponse.new(422, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors?).to be false
      expect(result.errors).to be_empty
    end

    it 'returns no errors on additional, not required properties' do
      response_body = json_dump([{ id: 42, name: 'hans', something: 'else' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors).to be_empty
    end

    it 'returns no errors if OAS file has no content' do
      expect_any_instance_of(OasParser::Response).to receive(:content) { nil }
      response = Rack::MockResponse.new(200, headers, 'body')
      result = subject.validate(request, response)
      expect(result.errors?).to be false
      expect(result.errors).to be_empty
    end

    it 'returns no errors if OAS file has no content schema specified' do
      empty_content = { 'application/json' => {} }
      expect_any_instance_of(OasParser::Response).to receive(:content) { empty_content }
      response = Rack::MockResponse.new(200, headers, 'body')
      result = subject.validate(request, response)
      expect(result.errors?).to be false
      expect(result.errors).to be_empty
    end
  end

  describe 'invalid response' do
    it 'fails on unknown http method' do
      request = begin
        env = Rack::MockRequest.env_for('/pets', method: 'PATCH')
        Rack::Request.new(env)
      end
      response_body = json_dump([{ id: 'string', name: 'hans' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors?).to be true
      expect(result.errors.first).to eq "HTTP method not found: 'patch'"
    end

    it 'fails on unknown status' do
      env = Rack::MockRequest.env_for('/pets/1')
      request = Rack::Request.new(env)
      response_body = json_dump([{ id: 2, name: 'Voldemort' }])
      response = Rack::MockResponse.new(201, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors?).to be true
      expect(result.errors.first).to eq "Response code not found: '201'"
    end

    it 'fails on wrong content type' do
      response_body = json_dump([{ id: 2, name: 'Voldemort' }])
      headers = { Rack::CONTENT_TYPE => 'application/xml' }
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors?).to be true
      expect(result.errors.first).to eq "Content type not found: 'application/xml'"
    end

    it 'returns errors on missing property' do
      response_body = json_dump([{ id: 42 }, { id: 2, name: 'Voldemort' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors?).to be true
      expect(result.errors.first).to eq(
        'data' => { 'id' => 42 },
        'data_pointer' => '/0',
        'details' => { 'missing_keys' => ['name'] },
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
      )
    end

    it 'returns errors on wrong property type' do
      response_body = json_dump([{ id: 'string', name: 'hans' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors.first).to eq(
        'data' => 'string',
        'data_pointer' => '/0/id',
        'schema' => { 'format' => 'int64', 'type' => 'integer' },
        'schema_pointer' => '/items/properties/id',
        'type' => 'integer'
      )
    end
  end
end

# frozen_string_literal: true

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
      response_body = json_dump([
                                  { id: 42, name: 'hans' },
                                  { id: 2, name: 'Voldemort' }
                                ])
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
      expect_any_instance_of(OpenapiFirst::Operation).to receive(:response_for) { {} }
      response = Rack::MockResponse.new(200, headers, 'body')
      result = subject.validate(request, response)
      expect(result.errors?).to be false
      expect(result.errors).to be_empty
    end

    it 'returns no errors if OAS file has no response_for schema specified' do
      empty_content = { 'application/json' => {} }
      expect_any_instance_of(OpenapiFirst::Operation)
        .to receive(:response_for) { { 'content' => empty_content } }
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
      expect(result.errors.first).to eq "Could not find definition for PATCH '/pets' in API description ./spec/data/petstore.yaml" # rubocop:disable Layout/LineLength
    end

    it 'fails on unknown status' do
      env = Rack::MockRequest.env_for('/pets/1')
      request = Rack::Request.new(env)
      response_body = json_dump([{ id: 2, name: 'Voldemort' }])
      response = Rack::MockResponse.new(201, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors?).to be true
      expect(result.errors.first).to eq "Response status code or default not found: 201 for 'GET /pets/{petId}'"
    end

    it 'fails on wrong content type' do
      response_body = json_dump([{ id: 2, name: 'Voldemort' }])
      headers = { Rack::CONTENT_TYPE => 'application/xml' }
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors?).to be true
      expect(result.errors.first).to eq(
        "Content type not found: 'application/xml'"
      )
    end

    it 'returns errors on missing property' do
      response_body = json_dump([{ id: 42 }, { id: 2, name: 'Voldemort' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors?).to be true
      error = result.errors.first
      expect(error[:title]).to eq('is missing required properties: name')
    end

    it 'returns errors on wrong property type' do
      response_body = json_dump([{ id: 'string', name: 'hans' }])
      response = Rack::MockResponse.new(200, headers, response_body)
      result = subject.validate(request, response)
      expect(result.errors.first[:title]).to eq('should be a integer')
    end
  end
end

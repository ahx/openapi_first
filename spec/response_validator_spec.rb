# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'openapi_first/response_validation/validator'

RSpec.describe OpenapiFirst::ResponseValidation::Validator do
  let(:spec) { './spec/data/petstore.yaml' }

  let(:subject) do
    operation = OpenapiFirst.load(spec).request(request).operation
    described_class.new(operation)
  end

  let(:request) do
    env = Rack::MockRequest.env_for('/pets')
    Rack::Request.new(env)
  end

  let(:headers) { { Rack::CONTENT_TYPE => 'application/json' } }

  describe 'valid response' do
    let(:response) do
      response_body = json_dump([
                                  { id: 42, name: 'hans' },
                                  { id: 2, name: 'Voldemort' }
                                ])
      Rack::Response.new(response_body, 200, headers)
    end

    it 'raises nothing' do
      subject.validate(response)
    end

    it 'falls back to the default' do
      response_body = JSON.dump(code: 422, message: 'Not good!')
      response = Rack::Response.new(response_body, 422, headers)
      subject.validate(response)
    end

    it 'returns no errors on additional, not required properties' do
      response_body = json_dump([{ id: 42, name: 'hans', something: 'else' }])
      response = Rack::Response.new(response_body, 200, headers)
      subject.validate(response)
    end

    describe 'when operation response has has no content defined' do
      let(:spec) { './spec/data/no-response-content.yaml' }
      let(:response) { Rack::Response.new('body', 200, headers) }
      let(:request) { Rack::Request.new(Rack::MockRequest.env_for('/')) }

      it 'returns no errors' do
        subject.validate(response)
      end

      describe 'when content type is empty' do
        let(:request) { Rack::Request.new(Rack::MockRequest.env_for('/empty-content')) }

        it 'returns no errors' do
          subject.validate(response)
        end
      end
    end
  end

  describe 'invalid response' do
    context 'when response status is unknown' do
      let(:request) { Rack::Request.new(Rack::MockRequest.env_for('/pets/12')) }

      it 'fails' do
        response_body = json_dump({ id: 2, name: 'Voldemort' })
        response = Rack::Response.new(response_body, 201, headers)
        expect do
          subject.validate(response)
        end.to raise_error OpenapiFirst::ResponseInvalid
      end
    end

    it 'fails on wrong content type' do
      response_body = json_dump([{ id: 2, name: 'Voldemort' }])
      headers = { Rack::CONTENT_TYPE => 'application/xml' }
      response = Rack::Response.new(response_body, 200, headers)
      expect do
        subject.validate(response)
      end.to raise_error OpenapiFirst::ResponseInvalid
    end

    it 'returns errors on missing property' do
      response_body = json_dump([{ id: 42 }, { id: 2, name: 'Voldemort' }])
      response = Rack::Response.new(response_body, 200, headers)
      expect do
        subject.validate(response)
      end.to raise_error OpenapiFirst::ResponseInvalid
    end

    it 'returns errors on wrong property type' do
      response_body = json_dump([{ id: 'string', name: 'hans' }])
      response = Rack::Response.new(response_body, 200, headers)
      expect do
        subject.validate(response)
      end.to raise_error OpenapiFirst::ResponseInvalid
    end
  end
end

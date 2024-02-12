# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'openapi_first/response_validation/validator'

RSpec.describe OpenapiFirst::ResponseValidation::Validator do
  let(:spec) { './spec/data/petstore.yaml' }

  let(:path) { '/pets' }
  let(:operation) { OpenapiFirst.load(spec).path(path).operation('get') }
  let(:subject) { described_class.new(operation, openapi_version: '3.1') }

  let(:headers) { { Rack::CONTENT_TYPE => 'application/json' } }

  let(:response) do
    OpenapiFirst::RuntimeResponse.new(
      operation,
      rack_response,
      validator: subject
    )
  end

  context 'with a valid response' do
    let(:rack_response) do
      response_body = json_dump([
                                  { id: 42, name: 'hans' },
                                  { id: 2, name: 'Voldemort' }
                                ])
      Rack::Response.new(response_body, 200, headers)
    end

    it 'raises nothing' do
      subject.validate(response)
    end

    context 'when response is not defined, but there is a default' do
      let(:rack_response) do
        response_body = JSON.dump(code: 422, message: 'Not good!')
        Rack::Response.new(response_body, 422, headers)
      end

      it 'falls back to the default' do
        subject.validate(response)
      end
    end

    context 'with additional, not required properties' do
      let(:rack_response) do
        response_body = json_dump([{ id: 42, name: 'hans', something: 'else' }])
        Rack::Response.new(response_body, 200, headers)
      end

      it 'returns no errors' do
        subject.validate(response)
      end
    end

    context 'when operation response has has no content defined' do
      let(:spec) { './spec/data/no-response-content.yaml' }
      let(:rack_response) { Rack::Response.new('body', 200, headers) }
      let(:path) { '/' }

      it 'returns no errors' do
        expect(subject.validate(response)).to be_nil
      end

      context 'when content type is empty' do
        let(:path) { '/empty-content' }

        it 'returns no errors' do
          subject.validate(response)
        end
      end
    end
  end

  describe 'invalid response' do
    context 'when response status is unknown' do
      let(:path) { '/pets/{petId}' }

      let(:rack_response) do
        response_body = json_dump({ id: 2, name: 'Voldemort' })
        Rack::Response.new(response_body, 201, headers)
      end

      it 'fails' do
        expect do
          subject.validate(response).raise!
        end.to raise_error OpenapiFirst::ResponseNotFoundError
      end
    end

    context 'with wrong content-type' do
      let(:rack_response) do
        response_body = json_dump([{ id: 2, name: 'Voldemort' }])
        headers = { Rack::CONTENT_TYPE => 'application/xml' }
        Rack::Response.new(response_body, 200, headers)
      end

      it 'fails on wrong content type' do
        expect do
          subject.validate(response).raise!
        end.to raise_error OpenapiFirst::ResponseInvalidError
      end
    end

    context 'with missing property' do
      let(:rack_response) do
        response_body = json_dump([{ id: 42 }, { id: 2, name: 'Voldemort' }])
        Rack::Response.new(response_body, 200, headers)
      end

      it 'fails' do
        expect do
          subject.validate(response).raise!
        end.to raise_error OpenapiFirst::ResponseInvalidError
      end
    end

    context 'with wrong property type' do
      let(:rack_response) do
        response_body = json_dump([{ id: 'string', name: 'hans' }])
        Rack::Response.new(response_body, 200, headers)
      end

      it 'fails' do
        expect do
          subject.validate(response).raise!
        end.to raise_error OpenapiFirst::ResponseInvalidError
      end
    end
  end
end

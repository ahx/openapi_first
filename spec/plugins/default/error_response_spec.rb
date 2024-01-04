# frozen_string_literal: true

require 'spec_helper'
require 'openapi_first/plugins/default'

RSpec.describe OpenapiFirst::Plugins::Default::ErrorResponse do
  let(:env) { {} }
  let(:validation_result) { OpenapiFirst::Schema.new(schema, openapi_version: '3.1').validate(data) }

  it 'returns application/problem+json' do
    error_response = described_class.new(
      failure: OpenapiFirst::RequestValidation::Failure.new(:invalid_body)
    )
    response = Rack::MockResponse[*error_response.render]
    expect(response.content_type).to eq 'application/problem+json'
  end

  context 'with invalid body' do
    let(:schema) do
      {
        'type' => 'object',
        'properties' => {
          'data' => {
            'type' => 'object',
            'required' => ['mandatory'],
            'properties' => {
              'name' => { 'type' => 'string' },
              'numberOfLegs' => { 'type' => 'integer', 'minimum' => 2 },
              'mandatory' => { 'type' => 'string' }
            }
          }
        }
      }
    end

    let(:data) do
      { 'data' => { 'name' => 21, 'numberOfLegs' => 1 } }
    end

    subject(:error_response) do
      described_class.new(
        failure: OpenapiFirst::RequestValidation::Failure.new(
          :invalid_body,
          errors: validation_result.errors
        )
      )
    end

    it 'renders an error about invalid body' do
      response = Rack::MockResponse[*error_response.render]
      expect(response.status).to eq(400)
      expect(MultiJson.load(response.body, symbolize_keys: true)).to eq(
        {
          title: 'Bad Request Body',
          status: 400,
          errors: [
            {
              message: 'value at `/data/name` is not a string',
              pointer: '/data/name',
              code: 'string'
            },
            {
              message: 'number at `/data/numberOfLegs` is less than: 2',
              pointer: '/data/numberOfLegs',
              code: 'minimum'
            },
            {
              message: 'object at `/data` is missing required properties: mandatory',
              pointer: '/data',
              code: 'required'
            }
          ]
        }
      )
    end
  end

  context 'with invalid query parameter' do
    let(:schema) do
      {
        'type' => 'object',
        'properties' => {
          'limit' => { 'type' => 'integer', 'maximum' => 100 }
        }
      }
    end

    let(:data) do
      { 'limit' => 101 }
    end

    subject(:error_response) do
      described_class.new(
        failure: OpenapiFirst::RequestValidation::Failure.new(
          :invalid_query,
          errors: validation_result.errors
        )
      )
    end

    it 'renders an error about invalid parameter' do
      response = Rack::MockResponse[*error_response.render]
      expect(response.status).to eq(400)
      expect(MultiJson.load(response.body, symbolize_keys: true)).to eq(
        {
          title: 'Bad Query Parameter',
          status: 400,
          errors: [
            {
              message: 'number at `/limit` is greater than: 100',
              parameter: 'limit',
              code: 'maximum'
            }
          ]
        }
      )
    end
  end

  context 'with unsupported media type' do
    subject(:error_response) do
      described_class.new(
        failure: OpenapiFirst::RequestValidation::Failure.new(
          :unsupported_media_type
        )
      )
    end

    it 'renders an error about invalid parameter' do
      response = Rack::MockResponse[*error_response.render]
      expect(response.status).to eq(415)
      expect(MultiJson.load(response.body, symbolize_keys: true)).to eq(
        title: 'Unsupported Media Type',
        status: 415
      )
    end
  end

  context 'when validation_result is nil' do
    subject(:error_response) do
      described_class.new(
        failure: OpenapiFirst::RequestValidation::Failure.new(
          :invalid_body
        )
      )
    end

    it 'renders an error without pointer or code' do
      response = Rack::MockResponse[*error_response.render]
      expect(response.status).to eq(400)
      expect(MultiJson.load(response.body, symbolize_keys: true)).to eq(
        {
          title: 'Bad Request Body',
          status: 400
        }
      )
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'openapi_first/plugins/jsonapi'

RSpec.describe OpenapiFirst::Plugins::Jsonapi::ErrorResponse do
  let(:env) { {} }
  let(:validation_result) { OpenapiFirst::Schema.new(schema, openapi_version: '3.1').validate(data) }

  it 'returns application/problem+json' do
    error_response = described_class.new(
      failure: OpenapiFirst::Failure.new(:invalid_body)
    )
    response = Rack::MockResponse[*error_response.render]
    expect(response.content_type).to eq 'application/vnd.api+json'
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
        failure: OpenapiFirst::Failure.new(
          :invalid_body,
          errors: validation_result.errors
        )
      )
    end

    it 'renders an error about invalid body' do
      response = Rack::MockResponse[*error_response.render]
      expect(response.status).to eq(400)
      body = MultiJson.load(response.body, symbolize_keys: true)
      expect(body).to eq({
                           errors: [
                             { status: '400',
                               source: { pointer: '/data/name' },
                               title: 'value at `/data/name` is not a string',
                               code: 'string' },
                             { status: '400',
                               source: { pointer: '/data/numberOfLegs' },
                               title: 'number at `/data/numberOfLegs` is less than: 2',
                               code: 'minimum' },
                             { status: '400',
                               source: { pointer: '/data' },
                               title: 'object at `/data` is missing required properties: mandatory',
                               code: 'required' }
                           ]
                         })
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
        failure: OpenapiFirst::Failure.new(
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
          errors: [
            { source: { parameter: 'limit' }, status: '400',
              title: 'number at `/limit` is greater than: 100', code: 'maximum' }
          ]
        }
      )
    end
  end

  context 'with invalid cookie value' do
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
        failure: OpenapiFirst::Failure.new(
          :invalid_cookie,
          errors: validation_result.errors
        )
      )
    end

    it 'renders an error about invalid parameter' do
      response = Rack::MockResponse[*error_response.render]
      expect(response.status).to eq(400)
      expect(MultiJson.load(response.body, symbolize_keys: true)).to eq(
        {
          errors: [
            { source: { cookie: 'limit' }, status: '400',
              title: 'number at `/limit` is greater than: 100', code: 'maximum' }
          ]
        }
      )
    end
  end

  context 'with invalid path segment value' do
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
        failure: OpenapiFirst::Failure.new(
          :invalid_path,
          errors: validation_result.errors
        )
      )
    end

    it 'renders an error about invalid parameter' do
      response = Rack::MockResponse[*error_response.render]
      expect(response.status).to eq(400)
      expect(MultiJson.load(response.body, symbolize_keys: true)).to eq(
        {
          errors: [
            { source: { parameter: 'limit' }, status: '400',
              title: 'number at `/limit` is greater than: 100', code: 'maximum' }
          ]
        }
      )
    end
  end

  context 'with invalid response header' do
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
        failure: OpenapiFirst::Failure.new(
          :invalid_header,
          errors: validation_result.errors
        )
      )
    end

    it 'renders an error about invalid parameter' do
      response = Rack::MockResponse[*error_response.render]
      expect(response.status).to eq(400)
      expect(MultiJson.load(response.body, symbolize_keys: true)).to eq(
        {
          errors: [
            { source: { header: 'limit' }, status: '400',
              title: 'number at `/limit` is greater than: 100', code: 'maximum' }
          ]
        }
      )
    end
  end

  context 'with unsupported media type' do
    subject(:error_response) do
      described_class.new(
        failure: OpenapiFirst::Failure.new(
          :unsupported_media_type
        )
      )
    end

    it 'renders an error about invalid parameter' do
      response = Rack::MockResponse[*error_response.render]
      expect(response.status).to eq(415)
      expect(MultiJson.load(response.body, symbolize_keys: true)).to eq(
        errors: [{ status: '415', title: 'Unsupported Media Type' }]
      )
    end
  end

  context 'when validation_result is nil' do
    subject(:error_response) do
      described_class.new(
        failure: OpenapiFirst::Failure.new(
          :invalid_body
        )
      )
    end

    it 'renders an error without pointer or code' do
      response = Rack::MockResponse[*error_response.render]
      expect(response.status).to eq(400)
      expect(MultiJson.load(response.body, symbolize_keys: true)).to eq(
        {
          errors: [{ status: '400', title: 'Bad Request' }]
        }
      )
    end
  end
end

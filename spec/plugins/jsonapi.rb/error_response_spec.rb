# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenapiFirst.plugin(:jsonapi)::ErrorResponse do
  describe '#render' do
    let(:env) { {} }

    context 'when validation_result is nil' do
      specify do
        error = described_class.new(
          failure: OpenapiFirst::RequestValidation::Failure.new(
            :invalid_body
          )
        )
        status, headers, body = error.render
        response = Rack::MockResponse.new(status, headers, body)
        expect(response.status).to eq(400)
        expect(response.content_type).to eq('application/vnd.api+json')
        expect(MultiJson.load(response.body, symbolize_keys: true)).to eq(
          { errors: [{ status: '400', title: 'Bad Request' }] }
        )
      end
    end

    context 'when validation_result is specified' do
      specify do
        schema = {
          'type' => 'object',
          'properties' => {
            'data' => {
              'type' => 'object',
              'properties' => {
                'name' => { 'type' => 'string' },
                'numberOfLegs' => { 'type' => 'integer' }
              }
            }
          }
        }
        data = { 'data' => { 'name' => 21, 'numberOfLegs' => 'four' } }
        validation = OpenapiFirst::Schema.new(schema, openapi_version: '3.1').validate(data)
        error = described_class.new(
          failure: OpenapiFirst::RequestValidation::Failure.new(
            :invalid_body,
            errors: validation.errors
          )
        )
        status, headers, body = error.render
        response = Rack::MockResponse.new(status, headers, body)
        expect(response.status).to eq(400)
        expect(response.content_type).to eq('application/vnd.api+json')
        expect(MultiJson.load(response.body, symbolize_keys: true)).to eq(
          { errors: [
            {
              status: '400',
              source: { pointer: '/data/name' },
              title: 'value at `/data/name` is not a string'
            },
            {
              status: '400',
              source: { pointer: '/data/numberOfLegs' },
              title: 'value at `/data/numberOfLegs` is not an integer'
            }
          ] }
        )
      end
    end
  end
end

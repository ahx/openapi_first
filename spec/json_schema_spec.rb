# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenapiFirst::Schema do
  let(:schema) do
    {
      'required' => ['count'],
      'properties' => {
        'count' => {
          'type' => 'integer'
        }
      }
    }
  end

  let(:validator) { described_class.new(schema) }

  let(:data) do
    { 'count' => 12 }
  end

  def validate(data)
    described_class.new(schema, openapi_version: '3.1').validate(data)
  end

  describe 'validate.error?' do
    it 'returns true if data is invalid' do
      expect(validate({}).error?).to be true
    end

    it 'returns false if data is valid' do
      expect(validate(data).error?).to be false
    end
  end

  describe 'validate.output' do
    it 'returns the validation output' do
      expect(validate(data).output['valid']).to be true
    end
  end

  describe 'validate.message' do
    it 'returns nil if data is valid' do
      expect(validate(data).message).to be_nil
    end

    it 'returns a message if data is invalid' do
      expect(validate({}).message).to eq 'object at root is missing required properties: count'
    end

    it 'returns a longer message with nested errors' do
      schema = {
        'required' => ['pets'],
        'properties' => {
          'count' => {
            'type' => 'integer'
          },
          'pets' => {
            'type' => 'array',
            'items' => {
              'required' => ['name'],
              'properties' => {
                'name' => {
                  'type' => 'string'
                }
              }
            }
          }
        }
      }
      validator = described_class.new(schema, openapi_version: '3.1')
      validation = validator.validate({ 'count' => 'a', 'pets' => [{ name: 12 }] })
      expect(validation.message).to eq 'value at `/count` is not an integer. value at `/pets/0/name` is not a string'

      validation = validator.validate({})
      expect(validation.message).to eq 'object at root is missing required properties: pets'
    end
  end

  describe 'validate.data' do
    it 'returns the original data' do
      expect(validate(data).data).to be data
    end
  end

  describe 'validate.schema' do
    it 'returns the original schema' do
      expect(validate(data).schema).to be schema
    end
  end
end

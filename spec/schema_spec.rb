# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenapiFirst::Schema do
  let(:schema) do
    {
      'type' => 'object',
      'required' => ['data'],
      'properties' => {
        'data' => {
          'type' => 'object',
          'required' => %w[count color],
          'additionalProperties' => false,
          'properties' => {
            'count' => {
              'type' => 'integer'
            },
            'null-or-string' => {
              'type' => %w[null string]
            },
            'color' => {
              'type' => 'string',
              'enum' => %w[red green]
            },
            'date_time' => {
              'type' => 'string',
              'format' => 'date-time'
            },
            'admin' => {
              'type' => 'boolean',
              'readOnly' => true
            },
            'pattern' => {
              'type' => 'string',
              'pattern' => '/[AB][1-9]/'
            },
            'list' => {
              'type' => 'array',
              'maxItems' => 2
            }
          }
        }
      }
    }
  end

  let(:validator) { described_class.new(schema) }

  let(:data) do
    { 'data' => { 'count' => 12, 'color' => 'red' } }
  end

  def validate(data)
    described_class.new(schema, openapi_version: '3.1', write: true).validate(data)
  end

  describe 'validate.error?' do
    it 'returns true if data is invalid' do
      expect(validate({}).error?).to be true
    end

    it 'returns false if data is valid' do
      expect(validate(data).error?).to be false
    end
  end

  describe 'validate.errors' do
    it 'is empty if validation succeeds' do
      expect(validate(data).errors).to be_empty
    end

    it 'returns errors if validation fails' do
      expect(validate({ 'foo' => 'bar' }).errors).to be_any
    end

    it 'has a message' do
      errors = validate({ 'data' => {} }).errors
      error = errors.first
      expect(error.message).to eq('object at `/data` is missing required properties: count, color')
    end

    it 'returns errors about missing fields' do
      errors = validate({ 'data' => {} }).errors
      expect(errors.count).to eq(1)
      error = errors.first
      expect(error.data_pointer).to eq('/data')
      expect(error.schema_pointer).to eq('/properties/data')
      expect(error.message).to eq('object at `/data` is missing required properties: count, color')
      expect(error.type).to eq('required')
      expect(error.details).to eq({ 'missing_keys' => %w[count color] })
    end

    it 'returns errors about invalid format' do
      data['data']['date_time'] = 'foo'
      errors = validate(data).errors
      expect(errors.count).to eq(1)
      error = errors.first
      expect(error.data_pointer).to eq('/data/date_time')
      expect(error.schema_pointer).to eq('/properties/data/properties/date_time')
      expect(error.message).to eq('value at `/data/date_time` does not match format: date-time')
      expect(error.type).to eq('format')
      expect(error.details).to be_nil
    end

    it 'returns errors about invalid types' do
      errors = validate({ 'data' => { 'count' => 'two', 'color' => 2, 'null-or-string' => 42 } }).errors
      expect(errors.count).to eq(4)
      expect(errors[0].data_pointer).to eq('/data/count')
      expect(errors[0].schema_pointer).to eq('/properties/data/properties/count')
      expect(errors[0].message).to eq('value at `/data/count` is not an integer')
      expect(errors[0].type).to eq('integer')
      expect(errors[0].details).to be_nil

      expect(errors[2].data_pointer).to eq('/data/color')
      expect(errors[2].schema_pointer).to eq('/properties/data/properties/color')
      expect(errors[2].message).to eq('value at `/data/color` is not a string')
      expect(errors[2].type).to eq('string')
      expect(errors[2].details).to be_nil

      expect(errors[1].data_pointer).to eq('/data/null-or-string')
      expect(errors[1].schema_pointer).to eq('/properties/data/properties/null-or-string')
      expect(errors[1].message).to eq('value at `/data/null-or-string` is not one of the types: ["null", "string"]')
      expect(errors[1].type).to eq('type')
      expect(errors[1].details).to be_nil
    end

    it 'returns errors about multiple errors on the same field' do
      errors = validate({ 'data' => { 'count' => 1, 'color' => 2 } }).errors
      expect(errors.count).to eq(2)
      expect(errors[0].data_pointer).to eq('/data/color')
      expect(errors[0].schema_pointer).to eq('/properties/data/properties/color')
      expect(errors[0].message).to eq('value at `/data/color` is not a string')
      expect(errors[0].type).to eq('string')
      expect(errors[0].details).to be_nil

      expect(errors[1].data_pointer).to eq('/data/color')
      expect(errors[1].schema_pointer).to eq('/properties/data/properties/color')
      expect(errors[1].message).to eq('value at `/data/color` is not one of: ["red", "green"]')
      expect(errors[1].type).to eq('enum')
      expect(errors[1].details).to be_nil
    end

    it 'returns errors about missing fields' do
      errors = validate({ 'data' => {} }).errors
      expect(errors.count).to eq(1)
      error = errors.first
      expect(error.data_pointer).to eq('/data')
      expect(error.schema_pointer).to eq('/properties/data')
      expect(error.message).to eq('object at `/data` is missing required properties: count, color')
      expect(error.type).to eq('required')
      expect(error.details).to eq({ 'missing_keys' => %w[count color] })
    end

    it 'returns errors about invalid pattern' do
      data['data']['pattern'] = 'foo'
      errors = validate(data).errors
      expect(errors.count).to eq(1)
      error = errors.first
      expect(error.data_pointer).to eq('/data/pattern')
      expect(error.schema_pointer).to eq('/properties/data/properties/pattern')
      expect(error.message).to eq('string at `/data/pattern` does not match pattern: /[AB][1-9]/')
      expect(error.type).to eq('pattern')
      expect(error.details).to be_nil
    end

    it 'returns errors about additional fields' do
      errors = validate({ 'data' => { 'additional' => true, 'count' => 2, 'color' => 'red' } }).errors
      expect(errors.count).to eq(1)
      error = errors.first
      expect(error.data_pointer).to eq('/data/additional')
      expect(error.schema_pointer).to eq('/properties/data/additionalProperties')
      expect(error.message).to eq(
        'object property at `/data/additional` is a disallowed additional property'
      )
      expect(error.type).to eq('schema')
      expect(error.details).to be_nil
    end

    it 'returns errors about readOnly fields' do
      errors = validate({ 'data' => { 'count' => 2, 'color' => 'red', 'admin' => true } }).errors
      expect(errors.count).to eq(1)
      error = errors.first
      expect(error.data_pointer).to eq('/data/admin')
      expect(error.schema_pointer).to eq('/properties/data/properties/admin')
      expect(error.message).to eq('value at `/data/admin` is `readOnly`')
      expect(error.type).to eq('readOnly')
      expect(error.details).to be_nil
    end

    it 'returns errors about readOnly fields' do
      data['data']['list'] = [1, 2, 3]
      errors = validate(data).errors
      expect(errors.count).to eq(1)
      error = errors.first
      expect(error.data_pointer).to eq('/data/list')
      expect(error.schema_pointer).to eq('/properties/data/properties/list')
      expect(error.message).to eq('array size at `/data/list` is greater than: 2')
      expect(error.type).to eq('maxItems')
      expect(error.details).to be_nil
    end
  end
end

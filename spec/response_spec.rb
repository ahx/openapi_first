# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe OpenapiFirst::Response do
  def build(status, content)
    operation = OpenapiFirst::Operation.new('/', 'get', {}, openapi_version: '3.1')
    described_class.new(status, { 'content' => content }, operation)
  end

  let(:media_type) { { 'schema' => { 'type' => 'object' } } }

  describe '#description' do
    it 'returns the description' do
      response = described_class.new('200', { 'description' => 'foo' }, nil)
      expect(response.description).to eq('foo')
    end
  end

  describe '#headers'

  describe '#status' do
    it 'returns the status as integer' do
      response = described_class.new('200', nil, nil)
      expect(response.status).to eq(200)
    end

    it 'keeps the status an integer' do
      response = described_class.new(200, nil, nil)
      expect(response.status).to eq(200)
    end

    it 'does not break with nil' do
      response = described_class.new(nil, nil, nil)
      expect(response.status).to eq(nil)
    end
  end

  describe '#content?' do
    it 'returns true if content is present' do
      response = build('200', { 'application/json' => media_type })
      expect(response.content?).to eq(true)
    end

    it 'returns false if content is empty' do
      response = build('200', {})
      expect(response.content?).to eq(false)
    end

    it 'returns false if content nil' do
      response = build('200', nil)
      expect(response.content?).to eq(false)
    end
  end

  describe '#schema_for' do
    it 'returns a schema for an exact match' do
      response = build('200', { 'application/json' => media_type })
      expect(response.schema_for('application/json')).to be_a(OpenapiFirst::Schema)
    end

    it 'ignores content type parameters' do
      response = build('200', { 'application/json' => media_type })
      expect(response.schema_for('application/json; charset=UTF8')).to be_a(OpenapiFirst::Schema)
    end

    it 'matches type/*' do
      response = build('200', { 'text/*' => media_type })
      expect(response.schema_for('text/plain')).to be_a(OpenapiFirst::Schema)
    end

    it 'matches */*' do
      response = build('200', { '*/*' => media_type })
      expect(response.schema_for('application/json')).to be_a(OpenapiFirst::Schema)
    end

    it 'returns nil for a media type object without schema' do
      media_type = {}
      response = build('200', { 'application/json' => media_type })
      expect(response.schema_for('application/json')).to be_nil
    end

    it 'returns nil for a miss match' do
      response = build('200', { 'application/xml' => media_type })
      expect(response.schema_for('application/json')).to be_nil
    end
  end
end

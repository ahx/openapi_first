# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe OpenapiFirst::RequestBody do
  def build(content)
    OpenapiFirst::Operation.new('/', 'get', content, openapi_version: '3.1').request_body
  end

  let(:media_type) { { 'schema' => { 'type' => 'object' } } }

  describe '#description' do
    it 'returns the description' do
      request_body = build({ 'get' => { 'requestBody' => { 'description' => 'foo' } } })
      expect(request_body.description).to eq('foo')
    end
  end

  describe '#schema_for' do
    it 'returns a schema for an exact match' do
      request_body = build({ 'get' => { 'requestBody' => { 'content' => { 'application/json' => media_type } } } })
      expect(request_body.schema_for('application/json')).to be_a(OpenapiFirst::Schema)
    end

    it 'ignores content type parameters' do
      request_body = build({ 'get' => { 'requestBody' => { 'content' => { 'application/json' => media_type } } } })
      expect(request_body.schema_for('application/json; charset=UTF8')).to be_a(OpenapiFirst::Schema)
    end

    it 'matches type/*' do
      request_body = build({ 'get' => { 'requestBody' => { 'content' => { 'text/*' => media_type } } } })
      expect(request_body.schema_for('text/plain')).to be_a(OpenapiFirst::Schema)
    end

    it 'matches */*' do
      request_body = build({ 'get' => { 'requestBody' => { 'content' => { '*/*' => media_type } } } })
      expect(request_body.schema_for('application/json')).to be_a(OpenapiFirst::Schema)
    end

    it 'returns nil for a media type object without schema' do
      media_type = {}
      request_body = build({ 'get' => { 'requestBody' => { 'content' => { 'application/json' => media_type } } } })
      expect(request_body.schema_for('application/json')).to be_nil
    end

    it 'returns nil for a miss match' do
      request_body = build({ 'get' => { 'requestBody' => { 'content' => { 'application/xml' => media_type } } } })
      expect(request_body.schema_for('application/json')).to be_nil
    end
  end
end

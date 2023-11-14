# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe OpenapiFirst::RequestBody do
  describe '#content_for' do
    def build(content)
      OpenapiFirst::Operation.new('/', 'get', content, openapi_version: '3.1').request_body
    end

    it 'returns true for an exact match' do
      request_body = build({ 'get' => { 'requestBody' => { 'content' => { 'application/json' => {} } } } })
      media_type = request_body.content_for('application/json')
      expect(media_type).to be_a(OpenapiFirst::MediaType)
    end

    it 'ignores content type parameters' do
      request_body = build({ 'get' => { 'requestBody' => { 'content' => { 'application/json' => {} } } } })
      media_type = request_body.content_for('application/json; charset=UTF8')
      expect(media_type).to be_a(OpenapiFirst::MediaType)
    end

    it 'matches type/*' do
      request_body = build({ 'get' => { 'requestBody' => { 'content' => { 'text/*' => {} } } } })
      media_type = request_body.content_for('text/plain')
      expect(media_type).to be_a(OpenapiFirst::MediaType)
    end

    it 'matches */*' do
      request_body = build({ 'get' => { 'requestBody' => { 'content' => { '*/*' => {} } } } })
      media_type = request_body.content_for('application/json')
      expect(media_type).to be_a(OpenapiFirst::MediaType)
    end

    it 'returns false for a miss match' do
      request_body = build({ 'get' => { 'requestBody' => { 'content' => { 'application/xml' => {} } } } })
      media_type = request_body.content_for('application/json')
      expect(media_type).to be_nil
    end
  end
end

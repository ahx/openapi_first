# frozen_string_literal: true

RSpec.describe OpenapiFirst::BodyParser do
  include Rack::Test::Methods

  def app = ->(_env) { Rack::Response.new.finish }

  context 'with application/json' do
    subject(:parser) { described_class['application/json'] }

    it 'parses JSON' do
      post '/', json_dump({ foo: 'bar' })

      body = parser.call(last_request)
      expect(body['foo']).to eq('bar')
    end
  end

  context 'with multipart/form-data' do
    subject(:parser) { described_class['multipart/form-data'] }

    it 'parses form-data' do
      uploaded_file = Rack::Test::UploadedFile.new('./spec/data/foo.txt')
      post '/', 'file' => uploaded_file

      body = parser.call(last_request)
      expect(body['file']).to eq(File.read('./spec/data/foo.txt'))
    end
  end

  context 'with application/x-www-form-urlencoded' do
    subject(:parser) { described_class['application/x-www-form-urlencoded'] }

    it 'parses form-data' do
      post '/', 'foo' => 'bar'

      body = parser.call(last_request)
      expect(body['foo']).to eq('bar')
    end
  end

  context 'with unknown/content-type' do
    subject(:parser) { described_class['unknown/content-type'] }

    it 'returns the raw body' do
      request = Rack::Request.new('CONTENT_TYPE' => 'unknown/content-type', 'rack.input' => StringIO.new('foo,bar'))
      body = parser.call(request)
      expect(body).to eq('foo,bar')
    end
  end
end

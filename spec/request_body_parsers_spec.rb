# frozen_string_literal: true

RSpec.describe OpenapiFirst::RequestBodyParsers do
  include Rack::Test::Methods

  def app = ->(_env) { Rack::Response.new.finish }

  context 'with application/json' do
    subject(:parser) { described_class['application/json'] }

    it 'parses JSON' do
      post '/', JSON.generate({ foo: 'bar' })

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

    context 'with an encoding map' do
      subject(:parser) do
        OpenapiFirst::RequestBodyParsers::MultipartBodyParser.new(
          encoding: { 'data' => { 'contentType' => 'application/json' } }
        )
      end

      it 'parses fields whose encoding contentType is JSON' do
        json_part = Rack::Test::UploadedFile.new(
          StringIO.new(JSON.generate(name: 'Quentin')),
          'application/json', original_filename: 'data.json'
        )
        post '/', 'data' => json_part

        body = parser.call(last_request)
        expect(body['data']).to eq('name' => 'Quentin')
      end

      it 'returns a Failure when a JSON-encoded field is malformed' do
        json_part = Rack::Test::UploadedFile.new(
          StringIO.new('{not valid'),
          'application/json', original_filename: 'data.json'
        )
        post '/', 'data' => json_part

        result = parser.call(last_request)
        expect(result).to be_a(OpenapiFirst::Failure)
        expect(result.type).to eq(:invalid_body)
        expect(result.message).to include(%(Failed to parse multipart field "data" as JSON))
      end

      it 'leaves fields without encoding untouched' do
        post '/', 'data' => Rack::Test::UploadedFile.new(
          StringIO.new(JSON.generate(name: 'Q')),
          'application/json', original_filename: 'data.json'
        ), 'other' => 'plain'

        body = parser.call(last_request)
        expect(body['other']).to eq('plain')
      end
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

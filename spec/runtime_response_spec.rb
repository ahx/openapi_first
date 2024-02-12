# frozen_string_literal: true

require 'action_dispatch'

RSpec.describe OpenapiFirst::RuntimeResponse do
  subject(:response) do
    definition.response(rack_request, rack_response)
  end

  let(:rack_request) do
    Rack::Request.new(Rack::MockRequest.env_for('/pets/1'))
  end

  let(:rack_response) do
    Rack::Response.new(JSON.dump([]), 200, { 'Content-Type' => 'application/json' })
  end

  let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

  describe '#operation' do
    it 'returns the operation that was found for the request' do
      expect(response.operation.operation_id).to eq('showPetById')
    end
  end

  describe '#validate!' do
    context 'if response is valid' do
      it 'returns nil' do
        expect(response.validate!).to be_nil
      end
    end

    context 'if response is invalid' do
      let(:rack_response) { Rack::Response.new(JSON.dump('foo'), 200, { 'Content-Type' => 'application/json' }) }

      it 'raises ResponseInvalidError' do
        expect do
          response.validate!
        end.to raise_error(OpenapiFirst::ResponseInvalidError)
      end
    end

    context 'if request is unknown' do
      let(:rack_request) { Rack::Request.new(Rack::MockRequest.env_for('/unknown')) }
      let(:rack_response) { Rack::Response.new(JSON.dump('foo'), 200, { 'Content-Type' => 'application/json' }) }

      it 'skips response validation and returns nil' do
        expect(response.validate!).to be_nil
      end
    end
  end

  describe 'validate' do
    context 'if response is valid' do
      it 'returns nil' do
        expect(response.validate).to be_nil
      end
    end

    context 'if response is invalid' do
      let(:rack_response) { Rack::Response.new(JSON.dump('foo'), 200, { 'Content-Type' => 'application/json' }) }

      it 'returns a Failure' do
        result = response.validate
        expect(result).to be_a(OpenapiFirst::Failure)
        expect(result.type).to eq :invalid_response_body
      end
    end
  end

  describe 'valid?' do
    context 'if response is valid' do
      it 'returns true' do
        expect(response).to be_valid
      end
    end

    context 'if response is invalid' do
      let(:rack_response) { Rack::Response.new(JSON.dump('foo'), 200, { 'Content-Type' => 'application/json' }) }

      it 'returns false' do
        expect(response).not_to be_valid
      end
    end
  end

  describe '#error' do
    context 'if response is valid' do
      it 'returns nil' do
        response.validate
        expect(response.error).to be_nil
      end
    end

    context 'if response is invalid' do
      let(:rack_response) { Rack::Response.new(JSON.dump('foo'), 200, { 'Content-Type' => 'application/json' }) }

      it 'returns a Failure' do
        response.validate
        result = response.error
        expect(result).to be_a(OpenapiFirst::Failure)
        expect(result.type).to eq :invalid_response_body
      end
    end
  end

  describe '#status' do
    it 'returns the HTTP status code of the response' do
      expect(response.status).to eq(200)
    end
  end

  describe '#content_type' do
    it 'returns the content-type of the response' do
      expect(response.content_type).to eq('application/json')
    end
  end

  describe '#body' do
    let(:rack_response) do
      app_response = Rack::Response.new(JSON.dump({ foo: :bar }), 200, { 'Content-Type' => 'application/json' }).to_a
      Rack::Response[*app_response]
    end

    it 'returns the parsed body' do
      expect(response.body).to eq('foo' => 'bar')
    end

    context 'without json content-type' do
      let(:rack_response) do
        Rack::Response.new(JSON.dump({ foo: :bar }))
      end

      it 'does not parse the body' do
        expect(response.body).to eq(JSON.dump({ foo: :bar }))
      end
    end

    context 'with invalid JSON' do
      let(:rack_response) do
        Rack::Response.new('{foobar}', 200, { 'Content-Type' => 'application/json' })
      end

      it 'raises a ParseError' do
        expect do
          response.body
        end.to raise_error OpenapiFirst::ParseError, 'Failed to parse response body as JSON'
      end
    end

    context 'when using Rails' do
      let(:rack_response) do
        app_response = ActionDispatch::Response.create(200, { 'Content-Type' => 'application/json' },
                                                       JSON.dump({ foo: :bar })).to_a
        Rack::Response[*app_response]
      end

      it 'returns the parsed body' do
        expect(response.body).to eq('foo' => 'bar')
      end
    end

    context 'when using Rails tests' do
      let(:rack_response) do
        app_response = Rack::Response.new(JSON.dump({ foo: :bar }), 200, { 'Content-Type' => 'application/json' })
        ActionDispatch::TestResponse.from_response(app_response)
      end

      it 'returns the parsed body' do
        expect(response.body).to eq('foo' => 'bar')
      end
    end
  end

  describe '#name' do
    it 'returns a name to identify the operation' do
      expect(response.name).to eq('GET /pets/{petId} response status: 200')
    end
  end

  describe '#known?' do
    it 'returns true' do
      expect(response.known?).to be true
    end

    context 'when response is not defined' do
      let(:rack_response) do
        Rack::Response.new('', 209)
      end

      it 'returns false' do
        expect(response.known?).to be false
      end
    end
  end

  describe '#known_status?' do
    it 'returns true' do
      expect(response.known_status?).to be true
    end

    context 'when status is not defined' do
      let(:rack_response) do
        Rack::Response.new('', 209)
      end

      it 'returns false' do
        expect(response.known_status?).to be false
      end
    end
  end

  describe '#headers' do
    let(:definition) { OpenapiFirst.load('./spec/data/response-header.yaml') }

    subject(:response) do
      operation = definition.path('/echo').operation('post')
      described_class.new(operation, rack_response, validator: ->(_) {})
    end

    let(:rack_response) do
      headers = {
        'Content-Type' => 'application/json',
        'Unknown' => 'Cow',
        'X-Id' => '42'
      }
      Rack::Response.new('', 201, headers)
    end

    it 'returns the unpacked headers as defined in the API description' do
      expect(response.headers).to eq(
        'Content-Type' => 'application/json',
        'X-Id' => 42
      )
    end

    context 'when response has no headers' do
      let(:rack_response) { Rack::Response.new }

      it 'is empty' do
        expect(response.headers).to eq({})
      end
    end

    context 'when no headers are defined' do
      let(:rack_response) do
        Rack::Response.new('', 204)
      end

      it 'is empty' do
        expect(response.headers).to eq({})
      end
    end

    context 'when response is not defined' do
      let(:rack_response) do
        Rack::Response.new('', 209)
      end

      it 'is empty' do
        expect(response.headers).to eq({})
      end
    end
  end
end

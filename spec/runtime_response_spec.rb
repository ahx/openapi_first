# frozen_string_literal: true

RSpec.describe OpenapiFirst::RuntimeResponse do
  subject(:response) do
    definition.request(rack_request).response(rack_response)
  end

  let(:rack_request) do
    Rack::Request.new(Rack::MockRequest.env_for('/pets/1'))
  end

  let(:rack_response) { Rack::Response.new(JSON.dump([]), 200, { 'Content-Type' => 'application/json' }) }

  let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

  describe 'validate!' do
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
        expect(result.error_type).to eq :invalid_response_body
      end
    end
  end
end

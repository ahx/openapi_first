# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

# frozen_string_literal: true

RSpec.describe OpenapiFirst do
  it 'has a version number' do
    expect(OpenapiFirst::VERSION).not_to be nil
  end

  include Rack::Test::Methods

  before do
    stub_const('SPEC_PATH', './spec/data/petstore-expanded.yaml')
    stub_const(
      'MyApi',
      Module.new do
        def self.update_pet(_params, _res)
          'updated'
        end
      end
    )
  end

  let(:request_body) do
    {
      'type' => 'pet',
      'attributes' => { 'name' => 'Frido' }
    }
  end

  describe '.app' do
    let(:app) do
      OpenapiFirst.app(SPEC_PATH, namespace: MyApi)
    end

    before do
      header Rack::CONTENT_TYPE, 'application/json'
    end

    it 'runs the app' do
      patch '/pets/1', json_dump(request_body)

      expect(last_response.body).to eq 'updated'
      expect(last_response.status).to eq 200
    end

    it 'raises OpenapiFirst::NotFoundError if path is unknown' do
      expect do
        patch '/unknown', json_dump(request_body)
      end.to raise_error OpenapiFirst::NotFoundError
    end

    describe 'if RACK_ENV is production' do
      let(:app) do
        stub_const('ENV', { 'RACK_ENV' => 'production' })
        OpenapiFirst.app(SPEC_PATH, namespace: MyApi)
      end

      it 'returns 404 if path is unknown and we are not testing' do
        patch '/unknown', json_dump(request_body)
        expect(last_response.status).to eq 404
      end
    end
  end

  describe '.load' do
    it 'returns a Definition' do
      expect(OpenapiFirst.load(SPEC_PATH)).to be_a OpenapiFirst::Definition
    end

    describe 'only option' do
      specify 'with empty filter' do
        definition = OpenapiFirst.load(SPEC_PATH, only: nil)
        expected = %w[find_pets create_pet find_pet delete_pet update_pet]
        expect(definition.operations.map(&:operation_id)).to eq expected
      end

      specify 'filtering paths' do
        definition = OpenapiFirst.load SPEC_PATH, only: '/pets'.method(:==)
        expected = %w[find_pets create_pet]
        expect(definition.operations.map(&:operation_id)).to eq expected
      end
    end
  end
end

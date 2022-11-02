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

  let(:spec_path) { './spec/data/petstore-expanded.yaml' }

  let(:namespace) do
    Module.new do
      def self.update_pet(_params, _res)
        'updated'
      end
    end
  end

  let(:request_body) do
    {
      'type' => 'pet',
      'attributes' => { 'name' => 'Frido' }
    }
  end

  describe '.app' do
    let(:app) do
      OpenapiFirst.app(spec_path, namespace: namespace)
    end

    before do
      header Rack::CONTENT_TYPE, 'application/json'
    end

    it 'runs the app' do
      patch '/pets/1', json_dump(request_body)

      expect(last_response.body).to eq 'updated'
      expect(last_response.status).to eq 200
    end

    it 'returns 404 is path is unknown' do
      patch '/unknown', json_dump(request_body)
      expect(last_response.status).to eq 404
    end

    describe 'if RACK_ENV is production' do
      let(:app) do
        stub_const('ENV', { 'RACK_ENV' => 'production' })
        OpenapiFirst.app(spec_path, namespace: namespace)
      end

      it 'returns 404 if path is unknown and we are not testing' do
        patch '/unknown', json_dump(request_body)
        expect(last_response.status).to eq 404
      end
    end
  end

  describe '.load' do
    it 'returns a Definition' do
      expect(OpenapiFirst.load(spec_path)).to be_a OpenapiFirst::Definition
    end

    describe 'only option' do
      specify 'with empty filter' do
        definition = OpenapiFirst.load(spec_path, only: nil)
        expected = %w[find_pets create_pet find_pet update_pet delete_pet]
        expect(definition.operations.map(&:operation_id)).to eq expected
      end

      specify 'filtering paths' do
        definition = OpenapiFirst.load spec_path, only: ->(path) { path == '/pets' }
        expected = %w[find_pets create_pet]
        expect(definition.operations.map(&:operation_id)).to eq expected
      end
    end
  end
end

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

  describe '.parse' do
    it 'loads a Hash' do
      definition = OpenapiFirst.parse(YAML.safe_load_file('./spec/data/petstore.yaml'))
      expect(definition.path('/pets').operation('get').operation_id).to eq('listPets')
    end

    it 'supports :only' do
      hash = YAML.safe_load_file('./spec/data/petstore.yaml')
      only = ->(path) { path == '/pets' }
      definition = OpenapiFirst.parse(hash, only:)
      expected = %w[/pets]
      expect(definition.paths.keys).to eq expected
    end

    it 'loads a Hash' do
      definition = OpenapiFirst.parse(YAML.safe_load_file('./spec/data/petstore.yaml'))
      expect(definition.path('/pets').operation('get').operation_id).to eq('listPets')
    end
  end

  describe '.load' do
    it 'returns a Definition' do
      expect(OpenapiFirst.load(spec_path)).to be_a OpenapiFirst::Definition
    end

    it 'works with YAML' do
      definition = OpenapiFirst.load('./spec/data/petstore.yaml')
      expect(definition.path('/pets').operation('get').operation_id).to eq('listPets')
    end

    it 'works with JSON' do
      definition = OpenapiFirst.load('./spec/data/petstore.json')
      expect(definition.path('/pets').operation('get').operation_id).to eq('listPets')
    end

    describe 'only option' do
      specify 'with empty filter' do
        definition = OpenapiFirst.load(spec_path, only: nil)
        expected = %w[/pets /pets/{id}]
        expect(definition.paths.keys).to eq expected
      end

      specify 'filtering paths' do
        definition = OpenapiFirst.load spec_path, only: ->(path) { path == '/pets' }
        expected = %w[/pets]
        expect(definition.paths.keys).to eq expected
      end
    end
  end
end

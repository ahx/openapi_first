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

  describe '.parse' do
    it 'loads a Hash' do
      definition = OpenapiFirst.parse(YAML.safe_load_file('./spec/data/petstore.yaml'))
      expect(definition.paths.first).to eq('/pets')
    end

    it 'supports :only' do
      hash = YAML.safe_load_file('./spec/data/petstore.yaml')
      only = ->(path) { path == '/pets' }
      definition = OpenapiFirst.parse(hash, only:)
      paths = definition.paths
      expect(paths).to include('/pets')
      expect(paths).not_to include('/pets/{petId}')
    end

    it 'loads a Hash' do
      definition = OpenapiFirst.parse(YAML.safe_load_file('./spec/data/petstore.yaml'))
      expect(definition.paths).to include('/pets')
    end
  end

  describe '.load' do
    it 'returns a Definition' do
      expect(OpenapiFirst.load(spec_path)).to be_a OpenapiFirst::Definition
    end

    it 'works with a lot of references' do
      definition = OpenapiFirst.load('./spec/data/fullofrefs.yaml')
      expect(definition.paths).to include('/foo')
    end

    it 'works with YAML' do
      definition = OpenapiFirst.load('./spec/data/petstore.yaml')
      expect(definition.paths).to include('/pets')
    end

    it 'works with JSON' do
      definition = OpenapiFirst.load('./spec/data/petstore.json')
      expect(definition.paths).to include('/pets')
    end

    it 'returns the same definition when a Definition object is passed in' do
      original_definition = OpenapiFirst.load('./spec/data/petstore.yaml')
      returned_definition = OpenapiFirst.load(original_definition)

      expect(returned_definition).to be(original_definition)
    end

    require 'benchmark'
    it 'works with a large document' do
      time = Benchmark.realtime do
        Timeout.timeout(2) do
          OpenapiFirst.load('./spec/data/large.yaml')
        end
      end
      expect(time).to be < 1
    end

    describe 'only option' do
      specify 'with empty filter' do
        definition = OpenapiFirst.load(spec_path, only: nil)
        expected = %w[/pets /pets/{id}]
        expect(definition.paths).to eq expected
      end

      specify 'filtering paths' do
        definition = OpenapiFirst.load spec_path, only: ->(path) { path == '/pets' }
        expected = %w[/pets]
        expect(definition.paths).to eq expected
      end
    end
  end
end

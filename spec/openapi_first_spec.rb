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

  describe '.configure' do
    it 'does not reset .configuration' do
      old_config_instance = described_class.configuration
      described_class.configure do |_|
        24
      end
      expect(described_class.configuration).to be(old_config_instance)
    end
  end

  describe '.load' do
    begin
      require 'multi_json'
      before do
        MultiJson.load_options = { symbolize_keys: true }
      end

      after do
        MultiJson.load_options = { symbolize_keys: false }
      end
    rescue LoadError # rubocop:disable Lint/SuppressedException
    end

    it 'returns a Definition' do
      expect(OpenapiFirst.load(spec_path)).to be_a OpenapiFirst::Definition
    end

    it 'works with a lot of references' do
      definition = OpenapiFirst.load('./spec/data/fullofrefs.yaml')
      expect(definition.paths).to include('/foo')
    end

    it 'works with numeric statuses' do
      definition = OpenapiFirst.load('./spec/data/numeric-status.yaml')
      expect(definition.paths).to include('/roles')
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

    context 'with a symbol' do
      it 'raises an exception if OAD has not been registered' do
        expect { OpenapiFirst.load(:unknown) }.to raise_error(OpenapiFirst::NotRegisteredError)
      end

      it 'returns the registered OAD' do
        OpenapiFirst.register(spec_path)
        oad = OpenapiFirst.load(:default)
        expect(oad.key).to eq(spec_path)
      end
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

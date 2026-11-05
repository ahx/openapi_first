# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

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

    it 'supports :path_prefix' do
      hash = YAML.safe_load_file('./spec/data/petstore.yaml')
      path_prefix = '/api/v1'
      definition = OpenapiFirst.parse(hash, path_prefix:)
      expect(definition.path_prefix).to eq(path_prefix)
    end

    it 'loads a Hash' do
      definition = OpenapiFirst.parse(YAML.safe_load_file('./spec/data/petstore.yaml'))
      expect(definition.paths).to include('/pets')
    end

    it 'resolves $refs through keys that are not strings' do
      pet = { 'type' => 'object', 'properties' => { 'name' => { 'type' => 'string' } } }
      definition = OpenapiFirst.parse({
                                        'openapi' => '3.1.0',
                                        'paths' => {
                                          '/pets' => {
                                            'get' => {
                                              'responses' => {
                                                200 => { 'description' => 'ok',
                                                         'content' => { 'application/json' => { 'schema' => pet } } }
                                              }
                                            },
                                            'post' => {
                                              'requestBody' => {
                                                'content' => {
                                                  'application/json' => {
                                                    'schema' => {
                                                      'type' => 'object',
                                                      'properties' => {
                                                        'pet' => {
                                                          '$ref' => '#/paths/~1pets/get/responses/200/content/application~1json/schema'
                                                        }
                                                      }
                                                    }
                                                  }
                                                }
                                              },
                                              'responses' => { 201 => { 'description' => 'created' } }
                                            }
                                          }
                                        }
                                      })
      request = Rack::Request.new(Rack::MockRequest.env_for('/pets', method: 'POST', input: '{"pet": {"name": 1}}',
                                                                     'CONTENT_TYPE' => 'application/json'))

      expect(definition.validate_request(request, raise_error: false).error.type).to eq(:invalid_body)
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
      # :nocov:
      before do
        MultiJSON.parse_options = { symbolize_names: true }
      end

      after do
        MultiJSON.parse_options = { symbolize_names: false }
      end
      # :nocov:
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

    it 'works with a media type that has no schema' do
      definition = OpenapiFirst.load('./spec/data/media-type-without-schema.yaml')
      expect(definition.paths).to include('/thing')
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

    context 'with a Definition and a block' do
      def validate_get(definition, path)
        definition.validate_request(Rack::Request.new(Rack::MockRequest.env_for(path)))
      end

      let(:called) { [] }

      let(:original_definition) do
        OpenapiFirst.load('./spec/data/petstore.yaml', path_prefix: '/api') do |config|
          config.after_request_validation { called << :original }
        end
      end

      let(:definition) do
        OpenapiFirst.load(original_definition) do |config|
          config.after_request_validation { called << :new }
        end
      end

      it 'returns a new Definition of the same document' do
        expect(definition).not_to be(original_definition)
        expect(definition.filepath).to eq(original_definition.filepath)
        expect(definition.paths).to eq(original_definition.paths)
        expect(definition.config).to be_frozen
      end

      it 'keeps the path_prefix' do
        expect(validate_get(definition, '/api/pets')).to be_valid
      end

      it 'calls the hooks of the given Definition and of the block' do
        validate_get(definition, '/api/pets')

        expect(called).to eq(%i[new original])
      end

      it 'does not change the given Definition' do
        validate_get(original_definition, '/api/pets')

        expect(called).to eq(%i[original])
      end
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

      it 'returns a new Definition of the registered OAD if a block is given' do
        registered = OpenapiFirst.register(spec_path)
        path = lambda(&:path)

        oad = OpenapiFirst.load(:default) { |config| config.path = path }

        expect(oad).not_to be(registered)
        expect(oad.key).to eq(spec_path)
        expect(oad.config.path).to be(path)
        expect(registered.config.path).to be_nil
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

    describe 'path_prefix option' do
      specify 'without a path prefix' do
        definition = OpenapiFirst.load(spec_path, path_prefix: nil)
        expect(definition.path_prefix).to be_nil
      end

      specify 'with a path prefix' do
        definition = OpenapiFirst.load(spec_path, path_prefix: '/api/v1')
        expect(definition.path_prefix).to eq('/api/v1')
      end
    end
  end
end

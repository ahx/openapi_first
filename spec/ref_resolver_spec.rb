# frozen_string_literal: true

require_relative '../lib/openapi_first/ref_resolver'

RSpec.describe OpenapiFirst::RefResolver do
  let(:contents) do
    {
      'definitions' => {
        'Thing' => { 'type' => 'object' },
        'A' => { 'name' => 'A' }
      },
      'hash' => {
        '$ref' => '#/definitions/Thing'
      },
      'array' => [
        { '$ref' => '#/definitions/A' },
        { 'name' => 'B' }
      ]
    }
  end

  subject(:doc) do
    described_class.for(contents)
  end

  describe '#[]' do
    it 'works across files' do
      file_path = './spec/data/splitted-train-travel-api/openapi.yaml'
      contents = OpenapiFirst::FileLoader.load(file_path)
      doc = described_class.for(contents, dir: File.dirname(file_path))
      target = doc['paths']['/stations']['get']['responses']['200']['headers']['RateLimit']['schema']
      schema = target.resolved
      expect(schema['type']).to eq('string')
    end

    it 'follows pointers through files' do
      file_path = './spec/data/petstore.yaml'
      contents = OpenapiFirst::FileLoader.load(file_path)
      doc = described_class.for(contents, dir: File.dirname(file_path))
      target = doc['components']['schemas']['Pet']

      expect(target.value).to eq({ '$ref' => './components/schemas/pet.yaml#/Pet' })
      expect(target.resolved).to eq(YAML.load_file('./spec/data/components/schemas/pet.yaml')['Pet'])
    end

    it 'returns nil if key is not found' do
      doc = described_class.for(contents)
      expect(doc['definitions']['unknown'].resolved).to eq(nil)
    end
  end

  describe '#fetch' do
    it 'works across files' do
      file_path = './spec/data/splitted-train-travel-api/openapi.yaml'
      contents = OpenapiFirst::FileLoader.load(file_path)
      doc = described_class.for(contents, dir: File.dirname(file_path))
      target = doc.fetch('paths').fetch('/stations')['get']['responses']['200']['headers']['RateLimit']['schema']
      expect(target.resolved['type']).to eq('string')
    end

    it 'raises KeyError if key is not found' do
      doc = described_class.for(contents)
      expect do
        doc.fetch('unknown')
      end.to raise_error KeyError
      expect do
        doc['hash'].fetch('unknown')
      end.to raise_error KeyError
    end
  end

  describe '#value' do
    it 'returns unresolved value' do
      expect(doc['hash'].value).to eq('$ref' => '#/definitions/Thing')
    end
  end

  describe '#resolved' do
    it 'returns the resolved value' do
      expect(doc['hash'].resolved).to eq('type' => 'object')
      expect(doc.resolved).to eq(contents)
    end

    it 'works with arrays' do
      doc = described_class.for(contents)
      expect(doc['array'].resolved).to eq([{ 'name' => 'A' }, { 'name' => 'B' }])
    end
  end

  describe '#each' do
    it 'works across files' do
      file_path = './spec/data/splitted-train-travel-api/openapi.yaml'
      contents = OpenapiFirst::FileLoader.load(file_path)
      doc = described_class.for(contents, dir: File.dirname(file_path))

      items = []
      doc.fetch('paths').each { |path, path_item| items << [path, path_item] }
      path, path_item = items.first

      expect(path).to eq('/stations')
      ok = path_item['get']['responses']['200']
      expect(ok['headers']['RateLimit']['schema'].resolved).to include('type' => 'string')
    end

    it 'applies the correct context to resolve refs' do
      contents = {
        'paths' => {
          '/' => {
            'parameters' => [
              { '$ref' => '#/components/parameters/page' }
            ]
          }
        },
        'components' => {
          'parameters' => {
            'page' => {
              'in' => 'query',
              'name' => 'page',
              'schema' => {
                'type' => 'integer'
              }
            }
          }
        }
      }

      doc = described_class.for(contents)
      parameters = doc.fetch('paths').first[1]['parameters']
      expect(parameters.resolved[0]['name']).to eq('page')
    end
  end
end

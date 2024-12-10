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
    described_class.new(contents)
  end

  describe '#[]' do
    it 'works across files' do
      file_path = './spec/data/splitted-train-travel-api/openapi.yaml'
      contents = OpenapiFirst::FileLoader.load(file_path)
      doc = described_class.new(contents, dir: File.dirname(file_path))
      target = doc['paths']['/stations']['get']['responses']['200']['headers']['RateLimit']['schema']
      schema = target.resolved
      expect(schema['type']).to eq('string')
    end

    it 'follows pointers through files' do
      file_path = './spec/data/petstore.yaml'
      contents = OpenapiFirst::FileLoader.load(file_path)
      doc = described_class.new(contents, dir: File.dirname(file_path))
      target = doc['components']['schemas']['Pet']
      target.value

      expect(target.value).to eq({ '$ref' => './components/schemas/pet.yaml#/Pet' })
      expect(target.resolved).to eq(YAML.load_file('./spec/data/components/schemas/pet.yaml')['Pet'])
    end

    it 'returns nil if key is not found' do
      doc = described_class.new(contents)
      expect(doc['definitions']['unknown'].resolved).to eq(nil)
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
  end

  describe '#each' do
    it 'works across files' do
      file_path = './spec/data/splitted-train-travel-api/openapi.yaml'
      contents = OpenapiFirst::FileLoader.load(file_path)
      doc = described_class.new(contents, dir: File.dirname(file_path))

      path, path_item = doc['paths'].first

      expect(path).to eq('/stations')
      ok = path_item['get']['responses']['200']
      expect(ok['headers']['RateLimit']['schema'].resolved).to include('type' => 'string')
    end
  end
end

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

  describe '#dir' do
    it 'returns the directory path' do
      filepath = './spec/data/splitted-train-travel-api/openapi.yaml'
      doc = described_class.load(filepath)
      expect(doc.dir).to eq(File.expand_path('./spec/data/splitted-train-travel-api'))

      node = doc['paths']['/stations']['get']
      expect(node.dir).to eq(File.expand_path('./spec/data/splitted-train-travel-api/paths'))

      node = node['responses']['200']['headers']['RateLimit']['schema']
      expect(node.dir).to eq(File.expand_path('./spec/data/splitted-train-travel-api/components/headers'))
    end
  end

  describe '#context' do
    it 'returns contents of the main file' do
      filepath = './spec/data/splitted-train-travel-api/openapi.yaml'
      doc = described_class.load(filepath)
      node = doc['info']
      expect(node.context['openapi']).to eq('3.1.0')
    end

    it 'returns contents of the main file when following internal refs' do
      filepath = './spec/data/train-travel-api/openapi.yaml'
      doc = described_class.load(filepath)
      node = doc['paths']['/stations']['get']['responses']['200']['headers']['RateLimit']['schema']
      expect(node.context['openapi']).to eq('3.1.0')
    end

    it 'returns contents of the referenced file' do
      filepath = './spec/data/splitted-train-travel-api/openapi.yaml'
      doc = described_class.load(filepath)
      node = doc['paths']['/stations']['get']['responses']
      expect(node.context.dig('get', 'description')).to start_with('Returns a list of all train stations')
    end

    it 'returns contents of the referenced file when pointing inside referenced files' do
      filepath = './spec/data/petstore.yaml'
      doc = described_class.load(filepath)
      node = doc['components']['schemas']['Pet']['required']
      expect(node.context).to eq(YAML.load_file('./spec/data/components/schemas/pet.yaml'))
    end
  end

  describe '#schema' do
    let(:ref_resolver) do
      ->(uri) { OpenapiFirst::FileLoader.load(uri.path) }
    end

    it 'returns a schema' do
      node = described_class.load('./spec/data/components/schemas/dog.yaml')
      schema = node.schema(ref_resolver:)
      expect(schema.valid?({ bark: 'woff' })).to eq(true)
      expect(schema.valid?({ bark: 2 })).to eq(false)
    end

    it 'accepts options' do
      node = described_class.for({ 'properties' => {
                                   'color' => {
                                     'type' => 'string',
                                     'default' => 'black'
                                   }
                                 } })
      data = {}
      schema = node.schema(insert_property_defaults: true)
      expect(schema.valid?(data)).to eq(true)
      expect(data['color']).to eq('black')
    end

    it 'uses the right context' do
      node = described_class.load('./spec/data/petstore.yaml')
      schema = node.dig('paths', '/pets/{petId}', 'get', 'responses', '200', 'content', 'application/json', 'schema').schema(ref_resolver:)
      expect(schema.valid?([{ id: 2, name: 'Spet' }])).to eq(true)
      expect(schema.valid?([{ id: 'two', name: 'Spet' }])).to eq(false)
    end

    it 'works with relative paths in the schema' do
      node = described_class.load('./spec/data/splitted-train-travel-api/openapi.yaml')
      schema = node.dig('paths', '/bookings', 'get', 'responses', '200', 'content', 'application/json', 'schema').schema(ref_resolver:)
      expect(schema.valid?({ data: [{ has_bicycle: true }] })).to eq(true)
      expect(schema.valid?({ data: [{ has_bicycle: 'red' }] })).to eq(false)
    end
  end

  describe '#[]' do
    it 'works across files' do
      filepath = './spec/data/splitted-train-travel-api/openapi.yaml'
      contents = OpenapiFirst::FileLoader.load(filepath)
      doc = described_class.for(contents, filepath:)
      node = doc['paths']['/stations']['get']['responses']['200']['headers']['RateLimit']['schema']
      expect(node.context['description']).to start_with('The RateLimit header')
      expect(node.resolved['type']).to eq('string')
    end

    it 'follows pointers through files' do
      filepath = './spec/data/petstore.yaml'
      contents = OpenapiFirst::FileLoader.load(filepath)
      doc = described_class.for(contents, filepath:)
      target = doc['components']['schemas']['Pet']

      expect(target.value).to eq({ '$ref' => './components/schemas/pet.yaml#/Pet' })
      expect(target.resolved).to eq(YAML.load_file('./spec/data/components/schemas/pet.yaml')['Pet'])
    end

    it 'returns nil if key is not found' do
      doc = described_class.for(contents)
      expect(doc['definitions']['unknown']).to eq(nil)
    end

    it 'works with arrays' do
      doc = described_class.for(contents)['array']
      expect(doc[0].resolved).to eq({ 'name' => 'A' })
      expect(doc[1].resolved).to eq({ 'name' => 'B' })
      # expect(doc.dig('array', 1, 'name').value).to eq('B')
      # expect(doc.dig('array', 0, 'unknown')).to eq(nil)
      # expect(doc.dig('array', 3)).to eq(nil)
      # expect(doc.dig('array', 3, 'name')).to eq(nil)
    end
  end

  describe '#dig' do
    it 'works across files' do
      filepath = './spec/data/splitted-train-travel-api/openapi.yaml'
      contents = OpenapiFirst::FileLoader.load(filepath)
      doc = described_class.for(contents, filepath:)
      node = doc.dig('paths', '/stations', 'get', 'responses', '200', 'headers', 'RateLimit', 'schema')
      expect(node.context['description']).to start_with('The RateLimit header')
      expect(node.resolved['type']).to eq('string')
    end

    it 'follows pointers through files' do
      filepath = './spec/data/petstore.yaml'
      contents = OpenapiFirst::FileLoader.load(filepath)
      doc = described_class.for(contents, filepath:)
      target = doc.dig('components', 'schemas', 'Pet')

      expect(target.value).to eq({ '$ref' => './components/schemas/pet.yaml#/Pet' })
      expect(target.resolved).to eq(YAML.load_file('./spec/data/components/schemas/pet.yaml')['Pet'])
    end

    it 'works with arrays' do
      doc = described_class.for(contents)
      expect(doc.dig('array', 0, 'name').value).to eq('A')
      expect(doc.dig('array', 1, 'name').value).to eq('B')
      expect(doc.dig('array', 0, 'unknown')).to eq(nil)
      expect(doc.dig('array', 3)).to eq(nil)
      expect(doc.dig('array', 3, 'name')).to eq(nil)
    end

    it 'returns nil if key is not found' do
      doc = described_class.for(contents)
      expect(doc.dig('definitions', 'unknown')).to eq(nil)
    end

    it 'returns nil if multiple keys are not found is not found' do
      doc = described_class.for(contents)
      expect(doc.dig('definitions', 'unknown', 'funknown')).to eq(nil)
    end
  end

  describe '#fetch' do
    it 'works across files' do
      filepath = './spec/data/splitted-train-travel-api/openapi.yaml'
      contents = OpenapiFirst::FileLoader.load(filepath)
      doc = described_class.for(contents, filepath:)
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

  describe '==' do
    it 'raises an error' do
      expect do
        doc['hash']['type'] == 'Dog'
      end.to raise_error "Don't call == on an unresolved value. Use .value == other instead."
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
      filepath = './spec/data/splitted-train-travel-api/openapi.yaml'
      contents = OpenapiFirst::FileLoader.load(filepath)
      doc = described_class.for(contents, filepath:)

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

    context 'when value is an array' do
      let(:contents) do
        {
          'definitions' => {
            'Thing' => { 'type' => 'object' },
            'A' => { 'name' => 'A' }
          },
          'array' => [
            { 'object' => { '$ref' => '#/definitions/A' } },
            { 'object' => { 'name' => 'B' } }
          ]
        }
      end

      it 'works' do
        results = []
        doc['array'].each do |node|
          results << node['object'].resolved
        end
        expect(results).to eq([
                                { 'name' => 'A' },
                                { 'name' => 'B' }
                              ])
      end
    end
  end
end

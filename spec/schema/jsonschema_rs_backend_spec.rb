# frozen_string_literal: true

require 'openapi_first/plugins/jsonschema_rs'

RSpec.describe OpenapiFirst::Schema::JsonschemaRsBackend do
  let(:file_loader) { OpenapiFirst::FileLoader.new }

  def backend(document = {}, filepath: nil)
    described_class.new(document:, filepath:, file_loader:)
  end

  def resolver
    OpenapiFirst::RefResolver.new(file_loader:)
  end

  def node_for(value, context: value, filepath: nil)
    resolver.for(value, filepath:, context:)
  end

  def errors_for(schema, data)
    OpenapiFirst::Schema::ValidationResult.new(backend.build_inline(schema).validate(data)).errors
  end

  describe '.supported_openapi_versions' do
    it 'supports only OpenAPI 3.1' do
      expect(described_class.supported_openapi_versions).to eq(%w[3.1])
    end
  end

  describe '#build_inline' do
    it 'validates a self-contained schema' do
      schema = backend.build_inline({ 'type' => 'integer' })
      expect(schema.valid?(2)).to be(true)
      expect(schema.valid?('two')).to be(false)
    end

    it 'exposes the raw schema via #value' do
      schema = backend.build_inline({ 'type' => 'integer', 'default' => 3 })
      expect(schema.value).to eq({ 'type' => 'integer', 'default' => 3 })
    end
  end

  describe '#build_node' do
    it 'returns a schema validator' do
      node = resolver.load('./spec/data/components/schemas/dog.yaml')
      schema = backend.build_node(node)
      expect(schema.valid?({ 'bark' => 'woff' })).to be(true)
      expect(schema.valid?({ 'bark' => 2 })).to be(false)
    end

    it 'resolves internal $refs against the surrounding document' do
      document = {
        'components' => { 'schemas' => { 'Pet' => { 'type' => 'object', 'required' => ['id'] } } },
        'subject' => { '$ref' => '#/components/schemas/Pet' }
      }
      node = node_for(document['subject'], context: document)
      schema = backend.build_node(node)
      expect(schema.valid?({ 'id' => 1 })).to be(true)
      expect(schema.valid?({})).to be(false)
    end

    it 'resolves nested and recursive $refs' do
      node = resolver.load('./spec/data/self-referencing.yaml')
                     .dig('paths', '/', 'get', 'responses', '200', 'content', 'application/json', 'schema')
      schema = backend.build_node(node)
      expect(schema.valid?({ 'foo' => 'a', 'bar' => { 'foo' => 'b' } })).to be(true)
      expect(schema.valid?({ 'foo' => 'a', 'bar' => { 'foo' => 2 } })).to be(false)
    end

    it 'resolves external file $refs relative to the node directory' do
      filepath = './spec/data/splitted-train-travel-api/openapi.yaml'
      node = resolver.load(filepath)
                     .dig('paths', '/bookings', 'get', 'responses', '200', 'content', 'application/json', 'schema')
      schema = backend.build_node(node)
      expect(schema.valid?({ 'data' => [{ 'has_bicycle' => true }] })).to be(true)
      expect(schema.valid?({ 'data' => [{ 'has_bicycle' => 'red' }] })).to be(false)
    end

    it 'raises for unsupported reference URI schemes' do
      schema = { 'type' => 'object', 'properties' => { 'x' => { '$ref' => 'https://example.com/schema.json' } } }
      node = node_for(schema, context: schema)
      expect { backend.build_node(node).valid?({ 'x' => 1 }) }.to raise_error(ArgumentError)
    end
  end

  describe 'default insertion' do
    it 'inserts top-level property defaults into the validated data' do
      node = node_for({ 'type' => 'object',
                        'properties' => { 'color' => { 'type' => 'string', 'default' => 'black' } } })
      data = {}
      backend.build_node(node).validate(data)
      expect(data['color']).to eq('black')
    end

    it 'keeps a value that is already present' do
      node = node_for({ 'type' => 'object',
                        'properties' => { 'color' => { 'type' => 'string', 'default' => 'black' } } })
      data = { 'color' => 'red' }
      backend.build_node(node).validate(data)
      expect(data['color']).to eq('red')
    end
  end

  describe 'error vocabulary mapping' do
    it 'maps a single type mismatch to the specific type keyword' do
      error = errors_for({ 'type' => 'integer' }, 'x').first
      expect(error).to have_attributes(type: 'integer', schema: { 'type' => 'integer' },
                                       message: 'value at root is not an integer')
    end

    it 'maps a multi-type mismatch to the generic type keyword' do
      error = errors_for({ 'type' => %w[integer string] }, true).first
      expect(error.type).to eq('type')
      expect(error.schema).to eq({ 'type' => %w[integer string] })
    end

    it 'maps required with missing keys' do
      error = errors_for({ 'type' => 'object', 'required' => ['a'] }, {}).first
      expect(error).to have_attributes(type: 'required', details: { 'missing_keys' => ['a'] },
                                       message: 'object at root is missing required properties: a')
    end

    it 'maps pattern' do
      error = errors_for({ 'type' => 'string', 'pattern' => '^a' }, 'b').first
      expect(error).to have_attributes(type: 'pattern', schema: { 'pattern' => '^a' },
                                       message: 'string at root does not match pattern: ^a')
    end

    it 'maps format' do
      error = errors_for({ 'type' => 'string', 'format' => 'date' }, 'nope').first
      expect(error).to have_attributes(type: 'format', schema: { 'format' => 'date' },
                                       message: 'value at root does not match format: date')
    end

    it 'maps const' do
      error = errors_for({ 'const' => 'foo' }, 'bar').first
      expect(error).to have_attributes(type: 'const', schema: { 'const' => 'foo' })
    end

    it 'maps enum' do
      error = errors_for({ 'enum' => [1, 2] }, 3).first
      expect(error).to have_attributes(type: 'enum', schema: { 'enum' => [1, 2] })
    end

    it 'maps minimum' do
      error = errors_for({ 'minimum' => 5 }, 3).first
      expect(error).to have_attributes(type: 'minimum', schema: { 'minimum' => 5 })
    end

    it 'maps maximum' do
      error = errors_for({ 'maximum' => 5 }, 9).first
      expect(error).to have_attributes(type: 'maximum', schema: { 'maximum' => 5 })
    end

    it 'falls back to the raw keyword name for other errors' do
      error = errors_for({ 'type' => 'string', 'maxLength' => 2 }, 'abcd').first
      expect(error).to have_attributes(type: 'maxLength', schema: nil)
    end

    it 'reports the instance and schema pointers' do
      error = errors_for({ 'type' => 'object', 'properties' => { 'a' => { 'type' => 'integer' } } },
                         { 'a' => 'x' }).first
      expect(error).to have_attributes(data_pointer: '/a', schema_pointer: '/properties/a/type', value: 'x')
    end
  end

  describe 'through the request/response pipeline' do
    around do |example|
      previous = OpenapiFirst.configuration.schema_backend
      OpenapiFirst.configuration.schema_backend = described_class
      example.run
    ensure
      OpenapiFirst.configuration.schema_backend = previous
    end

    def request(path, method: 'GET', body: nil)
      Rack::Request.new(
        Rack::MockRequest.env_for(path, method:, input: body, 'CONTENT_TYPE' => 'application/json')
      )
    end

    it 'raises when loading an OpenAPI 3.0 document' do
      expect { OpenapiFirst.load('./spec/data/petstore.yaml') }
        .to raise_error(OpenapiFirst::Error, /does not support OpenAPI 3.0/)
    end

    it 'validates a response body without object properties' do
      definition = OpenapiFirst.load('./spec/data/dice.yaml')
      response = Rack::Response.new('3', 200, { 'Content-Type' => 'application/json' })
      validated = definition.validate_response(request('/roll', method: 'POST'), response)
      expect(validated).to be_valid
    end

    describe 'readOnly (write access mode)' do
      let(:definition) { OpenapiFirst.load('./spec/data/readonly.yaml') }

      it 'rejects a readOnly property in the request body' do
        validated = definition.validate_request(
          request('/test', method: 'POST', body: '{"name":"foo","id":"123"}')
        )
        expect(validated).to be_invalid
        expect(validated.error.errors.map(&:message)).to eq(['value at `/id` is `readOnly`'])
      end

      it 'does not require a readOnly property in the request body' do
        validated = definition.validate_request(request('/test', method: 'POST', body: '{"name":"foo"}'))
        expect(validated).to be_valid
      end

      it 'still reports non-required errors in the request body' do
        validated = definition.validate_request(request('/test', method: 'POST', body: '{"name":123}'))
        expect(validated).to be_invalid
        expect(validated.error.errors.map(&:type)).to include('string')
      end

      it 'requires a readOnly property in the response body' do
        response = Rack::Response.new('{"name":"hans"}', 200, { 'Content-Type' => 'application/json' })
        validated = definition.validate_response(request('/test/42'), response)
        expect(validated).to be_invalid
      end

      it 'accepts a present readOnly property in the response body' do
        response = Rack::Response.new('{"id":"42","name":"hans"}', 200, { 'Content-Type' => 'application/json' })
        validated = definition.validate_response(request('/test/42'), response)
        expect(validated).to be_valid
      end
    end

    describe 'writeOnly (read access mode)' do
      let(:definition) { OpenapiFirst.load('./spec/data/writeonly.yaml') }

      it 'rejects a writeOnly property in the response body' do
        response = Rack::Response.new('{"name":"h","password":"x"}', 201, { 'Content-Type' => 'application/json' })
        validated = definition.validate_response(
          request('/test', method: 'POST', body: '{"name":"h","password":"x"}'), response
        )
        expect(validated).to be_invalid
      end

      it 'still requires a writeOnly property in the request body' do
        validated = definition.validate_request(request('/test', method: 'POST', body: '{"name":"h"}'))
        expect(validated).to be_invalid
        expect(validated.error.errors.map(&:type)).to include('required')
      end

      it 'accepts a writeOnly property in the request body' do
        validated = definition.validate_request(
          request('/test', method: 'POST', body: '{"name":"h","password":"x"}')
        )
        expect(validated).to be_valid
      end
    end

    it 'fires after_request_body_property_validation hooks for present properties' do
      called = []
      spec = {
        'openapi' => '3.1.0', 'info' => { 'title' => 't', 'version' => '1' },
        'paths' => { '/x' => { 'post' => {
          'requestBody' => { 'content' => { 'application/json' => {
            'schema' => { 'type' => 'object',
                          'properties' => { 'name' => { 'type' => 'string' }, 'age' => { 'type' => 'integer' } } }
          } } },
          'responses' => { '200' => { 'description' => 'ok' } }
        } } }
      }
      definition = OpenapiFirst.parse(spec) do |config|
        config.after_request_body_property_validation { |data, property, schema| called << [data, property, schema] }
      end
      definition.validate_request(request('/x', method: 'POST', body: '{"name": "Quentin"}'))
      # Only fires for properties present in the body, not the absent `age`.
      expect(called).to eq([[{ 'name' => 'Quentin' }, 'name', { 'type' => 'string' }]])
    end

    it 'validates request parameters and inserts parameter defaults' do
      spec = {
        'openapi' => '3.1.0', 'info' => { 'title' => 't', 'version' => '1' },
        'paths' => { '/things' => { 'get' => {
          'parameters' => [{ 'name' => 'limit', 'in' => 'query',
                             'schema' => { 'type' => 'integer', 'default' => 10 } }],
          'responses' => { '200' => { 'description' => 'ok' } }
        } } }
      }
      definition = OpenapiFirst.parse(spec)
      validated = definition.validate_request(request('/things'))
      expect(validated).to be_valid
      expect(validated.parsed_query['limit']).to eq(10)
    end

    it 'reports an invalid request parameter' do
      spec = {
        'openapi' => '3.1.0', 'info' => { 'title' => 't', 'version' => '1' },
        'paths' => { '/things' => { 'get' => {
          'parameters' => [{ 'name' => 'limit', 'in' => 'query', 'required' => true,
                             'schema' => { 'type' => 'integer' } }],
          'responses' => { '200' => { 'description' => 'ok' } }
        } } }
      }
      definition = OpenapiFirst.parse(spec)
      validated = definition.validate_request(request('/things?limit=abc'))
      expect(validated).to be_invalid
    end
  end
end

# frozen_string_literal: true

RSpec.describe OpenapiFirst::Definition::Operation do
  let(:operation) do
    path_item = OpenapiFirst::Definition::PathItem.new('/pets/{pet_id}', { 'get' => operation_object })
    described_class.new(path_item, 'get', operation_object)
  end

  let(:operation_object) do
    {
      'operationId' => 'get_pet',
      'parameters' => [
        { 'name' => 'limit', 'in' => 'query', 'schema' => { 'type' => 'integer' } }
      ],
      'responses' => {
        '200' => {
          'content' => {
            'application/json' => {
              'schema' => { 'type' => 'array' }
            },
            'application/vnd.api+json' => {
              'schema' => { 'type' => 'object', required: ['data'] }
            }
          }
        },
        'default' => {
          'description' => 'unexpected error'
        }
      }
    }
  end

  describe '#operation_id' do
    it 'returns the operationId' do
      expect(operation.operation_id).to eq 'get_pet'
    end
  end

  describe '#path_item' do
    it 'returns the path item' do
      expect(operation.path_item).to be_a(OpenapiFirst::Definition::PathItem)
    end
  end

  describe '#responses' do
    it 'returns all response definitions' do
      responses = operation.responses
      ok_response, jsonapi_response, default_response = responses.to_a

      expect(ok_response.status).to eq('200')
      expect(ok_response.content_type).to eq('application/json')
      expect(ok_response.content_schema).to eq({ 'type' => 'array' })

      expect(jsonapi_response.status).to eq('200')
      expect(jsonapi_response.content_type).to eq('application/vnd.api+json')
      expect(jsonapi_response.content_schema).to eq({ 'type' => 'object', required: ['data'] })

      expect(default_response.status).to eq('default')
      expect(default_response.content_type).to be_nil
    end
  end

  describe '#query_parameters' do
    it 'returns the query parameters of path and operation level' do
      path_item_object = {
        'get' => operation_object,
        'parameters' => [
          {
            'in' => 'query',
            'name' => 'other'
          }
        ]
      }
      path_item = OpenapiFirst::Definition::PathItem.new('/pets/{pet_id}', path_item_object)
      operation = described_class.new(path_item, 'get', operation_object)
      expect(operation.query_parameters.map { |p| p['name'] }).to eq %w[other limit]
    end
  end

  describe '#path_parameters' do
    it 'returns the path parameters on operation level' do
      expect(operation.path_parameters).to be_nil
    end
  end

  describe '#header_parameters' do
    it 'returns the header parameters' do
      expect(operation.header_parameters).to be_nil
    end
  end

  describe '#cookie_parameters' do
    it 'returns cookie parameters' do
      expect(operation.cookie_parameters).to be_nil
    end
  end

  describe '#[]' do
    it 'allows to access the resolved hash' do
      expect(operation['operationId']).to eq 'get_pet'
      expect(operation['responses'].dig('200', 'content', 'application/json', 'schema', 'type')).to eq 'array'
      expect(operation['responses'].dig('default', 'description')).to eq 'unexpected error'
    end
  end

  describe '#name' do
    it 'returns a human readable name' do
      expect(operation.name).to eq 'GET /pets/{pet_id}'
    end
  end

  describe '#method' do
    let(:spec) { OpenapiFirst.load('./spec/data/petstore-expanded.yaml') }

    it 'returns get' do
      expect(spec.operations.first.method).to eq 'get'
    end

    it 'returns post' do
      expect(spec.operations[1].method).to eq 'post'
    end
  end
end

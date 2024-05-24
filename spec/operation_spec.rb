# frozen_string_literal: true

RSpec.describe OpenapiFirst::Operation do
  let(:operation) do
    described_class.new('/pets/{pet_id}', 'post', operation_object, path_item_parameters: {})
  end

  let(:operation_object) do
    {
      'operationId' => 'create_pet',
      'parameters' => [
        { 'name' => 'limit', 'in' => 'query', 'schema' => { 'type' => 'integer' } }
      ],
      'requestBody' => {
        'required' => true,
        'content' => {
          'application/json' => {
            'schema' => { 'type' => 'object' }
          },
          'application/xml' => {
            'schema' => { 'type' => 'object' }
          }
        }
      },
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
      expect(operation.operation_id).to eq 'create_pet'
    end
  end

  describe '#query_parameters' do
    it 'returns the query parameters of path and operation level' do
      path_item_parameters = [
        {
          'in' => 'query',
          'name' => 'other'
        }
      ]
      operation = described_class.new('/pets/{pet_id}', 'get', operation_object, path_item_parameters:)
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
      expect(operation['operationId']).to eq 'create_pet'
      expect(operation['responses'].dig('200', 'content', 'application/json', 'schema', 'type')).to eq 'array'
      expect(operation['responses'].dig('default', 'description')).to eq 'unexpected error'
    end
  end

  describe '#name' do
    it 'returns a human readable name' do
      expect(operation.name).to eq 'POST /pets/{pet_id}'
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

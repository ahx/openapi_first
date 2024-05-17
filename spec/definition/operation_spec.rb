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

  describe '#response_for' do
    let(:spec) { OpenapiFirst.load('./spec/data/content-types.yaml') }
    let(:operation) { spec.operations.first }

    it 'finds the matching response object for a status code' do
      response = operation.response_for(200, 'application/json')
      expect(response).to be_a OpenapiFirst::Definition::Response
      expect(response.description).to eq 'Expected response to a valid request'
    end

    it 'finds an exact match without parameter' do
      response = operation.response_for(200, 'application/json')
      expect(response.content_type).to eq 'application/json'
    end

    it 'finds an exact match with parameter' do
      response = operation.response_for(200, 'application/json; profile=custom')
      expect(response.content_type).to eq 'application/json; profile=custom'
    end

    it 'finds a match while ignoring charset' do
      response = operation.response_for(200, 'application/json; charset=UTF8')
      expect(response.content_type).to eq 'application/json'
    end

    it 'finds text/* wildcard matcher' do
      response = operation.response_for(200, 'text/markdown')
      expect(response.content_type).to eq 'text/*'
    end

    it 'finds */* wildcard matcher' do
      response = operation.response_for(200, 'application/xml')
      expect(response.content_type).to eq '*/*'
    end

    context 'when status code cannot be found' do
      let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }
      let(:operation) { spec.path('/pets/{petId}').operation('get') }

      it 'returns nil' do
        expect(operation.response_for(201, 'application/json')).to be_nil
      end
    end

    context 'when API description has integers as status' do
      let(:operation) do
        operation_object = {
          'operationId' => 'get_pet',
          'parameters' => [
            { 'name' => 'limit', 'in' => 'query', 'schema' => { 'type' => 'integer' } }
          ],
          'responses' => {
            200 => {
              'description' => 'Expected response',
              'content' => {
                'application/json' => {
                  'schema' => { 'type' => 'array' }
                }
              }
            },
            'default' => {
              'description' => 'unexpected error'
            }
          }
        }
        described_class.new('/pets/{pet_id}', 'get', operation_object)
      end

      it 'just works, even though OAS wants strings' do
        response = operation.response_for(200, 'application/json')
        expect(response.description).to eq('Expected response')
      end
    end

    context 'when content type cannot be found' do
      let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }
      let(:operation) { spec.path('/pets/{petId}').operation('get') }

      it 'returns nil' do
        expect(operation.response_for(200, 'application/xml')).to be_nil
      end
    end

    context 'when default is defined be found' do
      let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }
      let(:operation) { spec.path('/pets').operation('get') }

      it 'falls back to the default' do
        result = operation.response_for(201, 'application/json')
        expect(result.description).to eq 'unexpected error'
      end
    end

    context 'when no content-type is defined' do
      let(:spec) { OpenapiFirst.load('./spec/data/content-types.yaml') }
      let(:operation) { spec.path('/without-content').operation('get') }

      it 'returns the response without content' do
        result = operation.response_for(204, 'application/json')
        expect(result.description).to eq 'no content'
      end
    end

    context 'when response object media type cannot be found' do
      let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }
      let(:operation) do
        operation_object = {
          'responses' => {
            '200' => {
              'content' => {
                'application/json' => {
                  'schema' => {
                    'type' => 'object'
                  }
                }
              }
            }
          }
        }
        described_class.new('/pets', 'get', operation_object)
      end

      it 'returns nil' do
        expect(operation.response_for(200, 'application/xml')).to be_nil
      end
    end

    context 'when response content is not defined' do
      let(:operation) do
        operation_object = {
          'responses' => {
            '200' => {
              'description' => 'Blank'
            }
          }
        }
        described_class.new('/pets', 'get', operation_object)
      end

      it 'returns a response without content-type' do
        response = operation.response_for(200, nil)
        expect(response.description).to eq 'Blank'
        expect(response.status).to eq 200
        expect(response.content_type).to be_nil
        expect(response.content_schema).to be_nil
      end

      it 'returns a response with unknown content-type' do
        response = operation.response_for(200, 'application/json')
        expect(response.description).to eq 'Blank'
        expect(response.status).to eq 200
        expect(response.content_type).to be_nil
        expect(response.content_schema).to be_nil
      end
    end

    context 'when response object media type is not defined' do
      let(:operation) do
        operation_object = {
          'responses' => {
            '200' => {
              'description' => 'Blank',
              'content' => {}
            }
          }
        }
        described_class.new('/pets', 'get', operation_object)
      end

      it 'returns a response without schema' do
        response = operation.response_for(200, 'application/json')
        expect(response.description).to eq 'Blank'
        expect(response.status).to eq 200
        expect(response.content_type).to be_nil
        expect(response.content_schema).to be_nil
      end
    end

    context 'when response content schema is not defined' do
      let(:operation) do
        operation_object = {
          'responses' => {
            '200' => {
              'content' => {
                'application/json' => {}
              }
            }
          }
        }
        described_class.new('/pets', 'get', operation_object)
      end

      it 'returns a response with content_type, but without schema' do
        response = operation.response_for(200, 'application/json')
        expect(response.status).to eq 200
        expect(response.content_type).to eq 'application/json'
        expect(response.content_schema).to be_nil
      end
    end
  end
end

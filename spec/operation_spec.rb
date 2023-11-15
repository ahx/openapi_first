# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe OpenapiFirst::Operation do
  let(:openapi_version) { '3.1' }

  let(:operation) do
    path_item = {
      'parameters' => [
        { 'name' => 'Accept-Version', 'in' => 'header', 'schema' => { 'type' => 'integer' } },
        { 'name' => 'utm', 'in' => 'query', 'schema' => { 'type' => 'string' } },
        { 'name' => 'pet_id', 'in' => 'path', 'schema' => { 'type' => 'string' } }
      ],
      'get' => {
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
    }
    described_class.new('/pets/{pet_id}', 'get', path_item, openapi_version:)
  end

  describe '#operation_id' do
    it 'returns the operationId' do
      expect(operation.operation_id).to eq 'get_pet'
    end
  end

  describe '#query_parameters' do
    it 'returns the query parameters on path and operation level' do
      expect(operation.query_parameters.map(&:name)).to eq %w[utm limit]
    end
  end

  describe '#path_parameters' do
    it 'returns the path parameters on path and operation level' do
      expect(operation.path_parameters.map(&:name)).to eq %w[pet_id]
    end
  end

  describe '#header_parameters' do
    it 'returns the header parameters' do
      expect(operation.header_parameters.map(&:name)).to eq %w[Accept-Version]
    end

    describe 'ignored headers' do
      # These are ignored, as described in the OpenAPI spec.
      %w[Content-Type Accept Authorization].each do |header|
        it "excludes the #{header} header" do
          path_item = {
            'parameters' => [
              { 'name' => header, 'in' => 'header', 'schema' => { 'type' => 'integer' } }
            ],
            'get' => {}
          }
          operation = described_class.new('/pets/{pet_id}', 'get', path_item, openapi_version:)
          expect(operation.header_parameters).to be_nil
        end
      end
    end
  end

  describe '#[], #dig' do
    it 'allows to access the resolved hash' do
      expect(operation['operationId']).to eq 'get_pet'
      expect(operation.dig('responses', '200', 'content', 'application/json', 'schema', 'type')).to eq 'array'
      expect(operation.dig('responses', 'default', 'description')).to eq 'unexpected error'
    end
  end

  describe '#name' do
    it 'returns a human readable name' do
      expect(operation.name).to eq 'GET /pets/{pet_id} (get_pet)'
    end
  end

  describe '#response_body_schema' do
    let(:spec) { OpenapiFirst.load('./spec/data/content-types.yaml') }
    let(:operation) { spec.operations[0] }

    it 'finds an exact match without parameter' do
      schema = operation.response_body_schema(200, 'application/json').schema
      expect(schema['title']).to eq 'Without parameter'
    end

    it 'finds an exact match with parameter' do
      schema = operation.response_body_schema(200, 'application/json; profile=custom').schema
      expect(schema['title']).to eq 'With profile'
    end

    it 'finds a match while ignorign charset' do
      schema = operation.response_body_schema(200, 'application/json; charset=UTF8').schema
      expect(schema['title']).to eq 'Without parameter'
    end

    it 'finds text/* wildcard matcher' do
      schema = operation.response_body_schema(200, 'text/markdown').schema
      expect(schema['title']).to eq 'Text wildcard'
    end

    it 'finds */* wildcard matcher' do
      schema = operation.response_body_schema(200, 'application/xml').schema
      expect(schema['title']).to eq 'Accept everything'
    end

    describe 'when status code cannot be found' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters.yaml') }
      let(:operation) { spec.operations.last }

      it 'returns nil' do
        expect(operation.response_body_schema(201, 'application/json')).to be_nil
      end
    end

    describe 'when response object media type cannot be found' do
      let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }
      let(:operation) { spec.operations[0] }

      it 'raises an exception' do
        expected_msg =
          "Response content type not found 'application/xml' for '#{operation.name}'"
        expect do
          operation.response_body_schema(200, 'application/xml')
        end.to raise_error OpenapiFirst::ResponseContentTypeNotFoundError,
                           expected_msg
      end
    end

    describe 'when response content is not defined' do
      before do
        expect(operation).to receive(:response_for).with(200) do
          { 'description' => 'Blank' }
        end
      end

      it 'returns nil' do
        schema = operation.response_body_schema(200, 'application/json')
        expect(schema).to be_nil
      end
    end

    describe 'when response object media type is not defined' do
      before do
        expect(operation).to receive(:response_for).with(200) do
          { 'content' => {} }
        end
      end

      it 'returns nil' do
        schema = operation.response_body_schema(200, 'application/json')
        expect(schema).to be_nil
      end
    end

    describe 'when response content schema is not defined' do
      before do
        expect(operation).to receive(:response_for).with(200) do
          { 'content' => { 'application/json' => {} } }
        end
      end

      it 'returns nil' do
        schema = operation.response_body_schema(200, 'application/json')
        expect(schema).to be_nil
      end
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

  describe '#read?' do
    it 'returns true if write? returns false' do
      operation = OpenapiFirst::Operation.new('/', 'get', {}, openapi_version:)
      expect(operation.read?).to be true
    end

    it 'returns false if write? returns true' do
      operation = OpenapiFirst::Operation.new('/', 'post', {}, openapi_version:)
      expect(operation.read?).to be false
    end
  end

  describe 'write?' do
    %w[POST PUT PATCH DELETE].each do |http_method|
      it "returns true for #{http_method}" do
        operation = OpenapiFirst::Operation.new('/', http_method.downcase, {}, openapi_version:)
        expect(operation.write?).to be true
      end
    end

    it 'returns false for GET' do
      operation = OpenapiFirst::Operation.new('/', 'get', {}, openapi_version:)
      expect(operation.write?).to be false
    end
  end

  describe '#response_for' do
    let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }
    let(:operation) { spec.operations.first }

    it 'finds the matching response object for a status code' do
      response = operation.response_for(200)
      expect(response).to be_a Hash
      description = response['description']
      expect(description).to eq 'A paged array of pets'
    end

    describe 'when status code cannot be found' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters.yaml') }
      let(:operation) { spec.operations.last }

      it 'returns nil' do
        expect(operation.response_for(201)).to be_nil
      end
    end
  end
end

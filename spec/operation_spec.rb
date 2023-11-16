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
      expect(response.description).to eq 'A paged array of pets'
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

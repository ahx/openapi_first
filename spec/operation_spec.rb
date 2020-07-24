# frozen_string_literal: true

require_relative 'spec_helper'
require 'openapi_first/operation'

RSpec.describe OpenapiFirst::Operation do
  let(:spec) { OpenapiFirst.load('./spec/data/parameters.yaml') }

  describe '#operation_id' do
    it 'returns the operationId' do
      operation = spec.operations.first
      expect(operation.operation_id).to eq 'search'
    end
  end

  describe '#name' do
    it 'returns a human readable name' do
      operation = spec.operations.first
      expect(operation.name).to eq 'GET /search (search)'
    end
  end

  describe '#parameters_json_schema' do
    let(:schema) do
      described_class.new(spec.operations.first).parameters_json_schema
    end

    let(:expected_schema) do
      {
        'type' => 'object',
        'required' => %w[
          term
        ],
        'properties' => {
          'birthdate' => {
            'format' => 'date',
            'type' => 'string'
          },
          'filter' => {
            'type' => 'object',
            'required' => ['tag'],
            'properties' => {
              'tag' => {
                'type' => 'string'
              },
              'other' => {
                'type' => 'object'
              }
            }
          },
          'include' => {
            'type' => 'string',
            'pattern' => '(parents|children)+(,(parents|children))*'
          },
          'limit' => {
            'type' => 'integer',
            'format' => 'int32'
          },
          'term' => {
            'type' => 'string'
          }
        }
      }
    end

    it 'returns the JSON Schema for the request' do
      expect(schema).to eq expected_schema
    end

    describe 'with flat named nested[params]' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters-flat.yaml') }

      let(:expected_schema) do
        {
          'type' => 'object',
          'required' => %w[term filter],
          'properties' => {
            'birthdate' => {
              'format' => 'date',
              'type' => 'string'
            },
            'filter' => {
              'type' => 'object',
              'required' => %w[tag id],
              'properties' => {
                'tag' => {
                  'type' => 'string'
                },
                'id' => {
                  'type' => 'integer'
                },
                'other' => {
                  'type' => 'string'
                }
              }
            },
            'include' => {
              'type' => 'string',
              'pattern' => '(parents|children)+(,(parents|children))*'
            },
            'limit' => {
              'type' => 'integer',
              'format' => 'int32'
            },
            'term' => {
              'type' => 'string'
            }
          }
        }
      end

      it 'converts it to a nested schema' do
        expect(schema).to eq expected_schema
      end
    end
  end

  describe '#response_schema_for' do
    let(:spec) { OpenapiFirst.load('./spec/data/content-types.yaml') }
    let(:operation) { spec.operations[0] }

    it 'finds an exact match without parameter' do
      schema = operation.response_schema_for(200, 'application/json')
      expect(schema['title']).to eq 'Without parameter'
    end

    it 'finds an exact match with parameter' do
      schema = operation.response_schema_for(200, 'application/json; profile=custom')
      expect(schema['title']).to eq 'With profile'
    end

    it 'finds a match while ignorign charset' do
      schema = operation.response_schema_for(200, 'application/json; charset=UTF8')
      expect(schema['title']).to eq 'Without parameter'
    end

    it 'finds text/* wildcard matcher' do
      schema = operation.response_schema_for(200, 'text/markdown')
      expect(schema['title']).to eq 'Text wildcard'
    end

    it 'finds */* wildcard matcher' do
      schema = operation.response_schema_for(200, 'application/xml')
      expect(schema['title']).to eq 'Accept everything'
    end

    describe 'when status code cannot be found' do
      let(:spec) { OpenapiFirst.load('./spec/data/parameters.yaml') }
      let(:operation) { spec.operations.last }

      it 'raises an exception' do
        expected_msg =
          "Response status code or default not found: 201 for '#{operation.name}'"
        expect do
          operation.response_schema_for(201, 'application/json')
        end.to raise_error OpenapiFirst::ResponseCodeNotFoundError, expected_msg
      end
    end

    describe 'when response object media type cannot be found' do
      let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }
      let(:operation) { spec.operations[0] }

      it 'raises an exception' do
        expected_msg =
          "Response content type not found 'application/xml' for '#{operation.name}'"
        expect do
          operation.response_schema_for(200, 'application/xml')
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
        schema = operation.response_schema_for(200, 'application/json')
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
        schema = operation.response_schema_for(200, 'application/json')
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
        schema = operation.response_schema_for(200, 'application/json')
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
      operation = OpenapiFirst::Operation.new(double(method: 'get'))
      expect(operation.read?).to be true
    end

    it 'returns false if write? returns true' do
      operation = OpenapiFirst::Operation.new(double(method: 'post'))
      expect(operation.read?).to be false
    end
  end

  describe 'write?' do
    %w[POST PUT PATCH DELETE].each do |http_method|
      it "returns true for #{http_method}" do
        operation = OpenapiFirst::Operation.new(double(method: http_method.downcase))
        expect(operation.write?).to be true
      end
    end

    it 'returns false for GET' do
      operation = OpenapiFirst::Operation.new(double(method: 'get'))
      expect(operation.write?).to be false
    end
  end

  describe '#request_body_schema_for' do
    let(:spec) { OpenapiFirst.load('./spec/data/content-types.yaml') }
    let(:operation) { spec.operations[1] }

    it 'finds an exact match without parameter' do
      schema = operation.request_body_schema_for('application/json')
      expect(schema['title']).to eq 'Without parameter'
    end

    it 'finds an exact match with parameter' do
      schema = operation.request_body_schema_for('application/json; profile=custom')
      expect(schema['title']).to eq 'With profile'
    end

    it 'finds a match while ignorign charset' do
      schema = operation.request_body_schema_for('application/json; charset=UTF8')
      expect(schema['title']).to eq 'Without parameter'
    end

    it 'finds text/* wildcard matcher' do
      schema = operation.request_body_schema_for('text/markdown')
      expect(schema['title']).to eq 'Text wildcard'
    end

    it 'finds */* wildcard matcher' do
      schema = operation.request_body_schema_for('application/xml')
      expect(schema['title']).to eq 'Accept everything'
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

      it 'raises an exception' do
        expected_msg =
          "Response status code or default not found: 201 for '#{operation.name}'"
        expect do
          operation.response_for(201)
        end.to raise_error OpenapiFirst::ResponseCodeNotFoundError, expected_msg
      end
    end
  end

  describe '#content_type_for' do
    it 'finds the response content type for a request' do
      operation = spec.operations.first
      content_type = operation.content_type_for(200)
      expect(content_type).to eq 'application/json'
    end

    describe 'when status code cannot be found' do
      it 'raises an exception' do
        operation = spec.operations[1]
        expected_msg =
          "Response status code or default not found: 201 for '#{operation.name}'"
        expect do
          operation.content_type_for(201)
        end.to raise_error OpenapiFirst::ResponseCodeNotFoundError, expected_msg
      end
    end
  end
end

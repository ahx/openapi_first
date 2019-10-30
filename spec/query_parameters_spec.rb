# frozen_string_literal: true

require_relative 'spec_helper'
require 'openapi_first/query_parameters'

RSpec.describe OpenapiFirst::QueryParameters do
  let(:spec) { OpenapiFirst.load('./spec/data/search.yaml') }

  describe '#to_json_schema' do
    let(:expected_schema) do
      {
        'type' => 'object',
        'required' => %w[
          term
        ],
        'additionalProperties' => false,
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
      query_parameters = described_class.new(
        operation: spec.operations.first,
        allow_unknown_parameters: false
      )
      expect(query_parameters.to_json_schema).to eq expected_schema
    end
  end
end

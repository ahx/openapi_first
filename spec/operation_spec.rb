# frozen_string_literal: true

require_relative 'spec_helper'
require 'openapi_first/operation'

RSpec.describe OpenapiFirst::Operation do
  let(:spec) { OpenapiFirst.load('./spec/data/parameters.yaml') }

  describe '#parameters_json_schema' do
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
      schema = described_class.new(spec.operations.first).parameters_json_schema
      expect(schema).to eq expected_schema
    end
  end
end

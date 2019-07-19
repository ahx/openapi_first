# frozen_string_literal: true

require_relative 'spec_helper'
require 'openapi_first/query_parameter_schemas'

RSpec.describe OpenapiFirst::QueryParameterSchemas do
  let(:spec) { OpenapiFirst.load('./spec/data/search.yaml') }

  describe '#find' do
    let(:subject) do
      described_class.new(allow_additional_parameters: false)
    end

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
      parameter_schema = subject.find(spec.operations.first)
      expect(parameter_schema).to eq expected_schema
    end
  end
end

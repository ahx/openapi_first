# frozen_string_literal: true

RSpec.describe OpenapiFirst::Refs do
  describe '.resolve_file' do
    it 'resolves refs' do
      resolved = described_class.resolve_file('spec/data/train-travel-api/openapi.yaml')
      expect(resolved.dig('paths', '/stations', 'get', 'responses', '200', 'headers', 'RateLimit', 'schema', 'type')).to eq('string')
    end

    it 'resolves refs across files' do
      resolved = described_class.resolve_file('spec/data/petstore.yaml')
      pp resolved.dig('paths', '/pets', 'get', 'responses', '200', 'content', 'application/json').inspect
      expect(resolved.dig('components', 'schemas', 'Pet', 'properties', 'name')).to eq({ 'type' => 'string' })
      expect(resolved.dig('paths', '/pets', 'get', 'responses', '200', 'content', 'application/json', 'schema', 'items', 'required')).to eq(%w[id name])
    end
  end

  describe '.resolve_data!' do
    it 'resolves refs in Hashes' do
      data = {
        '$definitions' => {
          'Thing' => { 'type' => 'object' }
        },
        'hash' => {
          '$ref' => '#/$definitions/Thing'
        }
      }
      resolved = described_class.resolve_data!(data, context: data, dir: '.')
      expect(resolved).to eq({
                               '$definitions' => {
                                 'Thing' => { 'type' => 'object' }
                               },
                               'hash' => {
                                 # '$ref' => '#/$definitions/Thing',
                                 'type' => 'object'
                               }
                             })
    end

    it 'resolves refs in Arrays' do
      data = {
        '$definitions' => {
          'Thing' => { 'type' => 'object' }
        },
        'array' => [
          {
            '$ref' => '#/$definitions/Thing'
          },
          {
            '$ref' => '#/$definitions/Thing'
          }
        ]
      }
      resolved = described_class.resolve_data!(data, context: data, dir: '.')
      expect(resolved).to eq({
                               '$definitions' => {
                                 'Thing' => { 'type' => 'object' }
                               },
                               'array' => [
                                 {
                                   # '$ref' => '#/$definitions/Thing',
                                   'type' => 'object'
                                 },
                                 {
                                   # '$ref' => '#/$definitions/Thing',
                                   'type' => 'object'
                                 }
                               ]
                             })
    end

    it 'returns the original object' do
      data = '42'
      resolved = described_class.resolve_data!(data, context: data, dir: '.')
      expect(resolved).to be(data)
    end
  end
end

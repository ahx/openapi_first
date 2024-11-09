require_relative '../lib/openapi_first/resolved'


RSpec.describe OpenapiFirst::Resolved do
  let(:original_hash) do
    {
      'definitions' => {
        'Thing' => { 'type' => 'object' },
        'A' => { 'name' => 'A' }
      },
      'hash' => {
        '$ref' => '#/definitions/Thing'
      },
      'array' => [
        { '$ref' => '#/definitions/A' },
        { 'name' => 'B' }
      ]
    }
  end

  let(:resolved) do
    described_class.new(original_hash)
  end

  describe '#resolved' do
    it 'gives access to the resolved values' do
      expect(resolved['hash'].resolved).to eq('type' => 'object')
      expect(resolved.resolved).to eq(original_hash)
    end
  end

  describe '#each' do
    it 'gives access to the resolved values' do
      resolved['hash'].each do |key, value|
        expect(key).to eq('type')
        expect(value).to eq('object')
      end
    end
  end
end

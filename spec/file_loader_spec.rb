# frozen_string_literal: true

RSpec.describe OpenapiFirst::FileLoader do
  describe '.load' do
    it 'loads .json' do
      contents = described_class.load('./spec/data/petstore.json')
      expect(contents['openapi']).to eq('3.0.0')
    end

    it 'loads .yaml' do
      contents = described_class.load('./spec/data/petstore.yaml')
      expect(contents['openapi']).to eq('3.0.0')
    end

    it 'loads .yml' do
      contents = described_class.load('./spec/data/petstore.yml')
      expect(contents['openapi']).to eq('3.0.0')
    end

    it 'raises FileNotFoundError if file was not found' do
      expect { described_class.load('./spec/data/unknown.yaml') }.to raise_error(OpenapiFirst::FileNotFoundError, 'File not found "./spec/data/unknown.yaml"')
    end
  end
end

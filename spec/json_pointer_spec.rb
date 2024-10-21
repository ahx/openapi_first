# frozen_string_literal: true

RSpec.describe OpenapiFirst::JsonPointer do
  describe '.append' do
    it 'escapes tilde and slash' do
      result = described_class.append('#', '/stations', '~italy')
      expect(result).to eq('#/~1stations/~0italy')
    end

    it 'URL escapes plus' do
      result = described_class.append('#', '/responses', 'content', 'application/problem+json')
      expect(result).to eq('#/~1responses/content/application~1problem%2Bjson')
    end

    it 'does not escape the first token' do
      result = described_class.append('#/paths', '/stations', 'responses')
      expect(result).to eq('#/paths/~1stations/responses')
    end
  end
end

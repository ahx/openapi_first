# frozen_string_literal: true

RSpec.describe OpenapiFirst::PathTemplate do
  describe '.template?' do
    it 'is true for a path with a variable' do
      expect(described_class.template?('/some/{thing}')).to be(true)
    end

    it 'is false for a static path' do
      expect(described_class.template?('/totally/static')).to be(false)
    end

    it 'is false for an unbalanced brace' do
      expect(described_class.template?('/some/{thing')).to be(false)
    end
  end

  describe '.variable?' do
    it 'is true for a segment that is exactly one variable' do
      expect(described_class.variable?('{id}')).to be(true)
    end

    it 'is false for a segment that mixes literals and variables' do
      expect(described_class.variable?('{name}.{ext}')).to be(false)
      expect(described_class.variable?('v{version}')).to be(false)
    end

    it 'is false for a literal segment' do
      expect(described_class.variable?('users')).to be(false)
    end
  end

  describe '.variable_names' do
    it 'returns the names in order of appearance' do
      expect(described_class.variable_names('/kebab-path/{ke-bab}/{under_score}.{ext}'))
        .to eq(%w[ke-bab under_score ext])
    end

    it 'returns an empty array for a static path' do
      expect(described_class.variable_names('/a/b')).to eq([])
    end
  end

  describe '.expand' do
    it 'replaces each variable with the value returned for its name' do
      result = described_class.expand('/users/{id}/files/{name}.{ext}', &:upcase)
      expect(result).to eq('/users/ID/files/NAME.EXT')
    end

    it 'returns a static path unchanged' do
      expect(described_class.expand('/a/b') { raise 'not called' }).to eq('/a/b')
    end
  end
end

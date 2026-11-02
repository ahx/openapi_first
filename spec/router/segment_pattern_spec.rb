# frozen_string_literal: true

RSpec.describe OpenapiFirst::Router::SegmentPattern do
  describe '#match' do
    it 'returns the variable values in order of appearance' do
      expect(described_class.new('{a}..{b}').match('some..other')).to eq(%w[some other])
    end

    it 'matches special characters in values' do
      expect(described_class.new('{bang}!').match('bang!boom!')).to eq(['bang!boom'])
    end

    it 'returns nil when the literal part does not match' do
      expect(described_class.new('{a}-{b}').match('1.2')).to be_nil
    end

    it 'returns nil when a variable would be empty' do
      expect(described_class.new('{name}.{ext}').match('.pdf')).to be_nil
    end

    it 'returns nil when the segment continues after the pattern' do
      expect(described_class.new('v{version}').match('v1/extra')).to be_nil
    end

    it 'matches the variable names when the segment spells the template' do
      expect(described_class.new('{name}.{ext}').match('{name}.{ext}')).to eq(%w[{name} {ext}])
    end
  end
end

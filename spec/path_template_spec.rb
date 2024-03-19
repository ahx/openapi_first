# frozen_string_literal: true

RSpec.describe OpenapiFirst::PathTemplate do
  describe '#match' do
    it 'returns empty params with exact string match' do
      expect(described_class.new('/a/b').match('/a/b')).to eq({})
    end

    it 'returns params with multiple matches' do
      expect(described_class.new('/{a}/{b}').match('/1/2')).to eq({ 'a' => '1', 'b' => '2' })
    end

    it 'ignores trailing slashes in paths' do
      expect(described_class.new('/{a}/{b}').match('/1/2/')).to eq({ 'a' => '1', 'b' => '2' })
    end

    it 'returns params with kebab-case names' do
      expect(described_class.new('/kebab-path/{ke-bab}/{under_score}').match('/kebab-path/1/2'))
        .to eq({ 'ke-bab' => '1', 'under_score' => '2' })
    end


    it 'returns params where variable is in the middle' do
      expect(described_class.new('/stuff/{id}/things').match('/stuff/42/things')).to eq({ 'id' => '42' })
    end

    it 'works with /stuff/{a}..{b}' do
      expect(described_class.new('/stuff/{a}..{b}').match('/stuff/some..other')).to eq({ 'a' => 'some',
                                                                                         'b' => 'other' })
    end

    it 'works with special characters in path' do
      expect(described_class.new('/stuff/{range}').match('/stuff/some..other')).to eq({ 'range' => 'some..other' })
      expect(described_class.new('/stuff/{bang}').match('/stuff/bang!boom!')).to eq({ 'bang' => 'bang!boom!' })
    end

    it 'returns nil without match' do
      expect(described_class.new('/{a}/middle/{b}').match('/1/2/3')).to be_nil
    end

    it 'returns nil when path has more parts' do
      expect(described_class.new('/foo/{id}').match('/foo/middle/bar')).to be_nil
    end

    it 'returns nil when path without variables does not match' do
      expect(described_class.new('/a/b').match('/1/2')).to be_nil
    end
  end
end

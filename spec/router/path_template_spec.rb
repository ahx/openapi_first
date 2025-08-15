# frozen_string_literal: true

RSpec.describe OpenapiFirst::Router::PathTemplate do
  let(:path_parameters) { [] }
  let(:use_patterns_for_path_matching) { false }

  describe '.template?' do
    specify do
      expect(described_class.template?('/totally/static')).to be(false)
      expect(described_class.template?('/some/{thing}')).to be(true)
    end
  end

  describe '#to_s' do
    specify do
      expect(
        described_class.new('/stations/{id}', path_parameters, use_patterns_for_path_matching).to_s
      ).to eq('/stations/{id}')
    end
  end

  describe '#match' do
    it 'returns empty params with exact string match' do
      expect(
        described_class.new('/a/b', path_parameters, use_patterns_for_path_matching)
          .match('/a/b')
      ).to eq({})
    end

    it 'returns params with multiple matches' do
      expect(
        described_class.new('/{a}/{b}', path_parameters, use_patterns_for_path_matching )
          .match('/1/2')
      ).to eq({ 'a' => '1', 'b' => '2' })
    end

    it 'ignores trailing slashes in paths' do
      expect(
        described_class.new('/{a}/{b}', path_parameters, use_patterns_for_path_matching)
          .match('/1/2/')
      ).to eq({ 'a' => '1', 'b' => '2' })
    end

    it 'returns params with kebab-case names' do
      expect(
        described_class.new('/kebab-path/{ke-bab}/{under_score}', path_parameters, use_patterns_for_path_matching)
          .match('/kebab-path/1/2')
      ).to eq({ 'ke-bab' => '1', 'under_score' => '2' })
    end

    it 'returns params where variable is in the middle' do
      expect(
        described_class.new('/stuff/{id}/things', path_parameters, use_patterns_for_path_matching)
          .match('/stuff/42/things')
      ).to eq({ 'id' => '42' })
    end

    it 'works with /stuff/{a}..{b}' do
      expect(
        described_class.new('/stuff/{a}..{b}', path_parameters, use_patterns_for_path_matching)
          .match('/stuff/some..other')
      ).to eq({ 'a' => 'some', 'b' => 'other' })
    end

    it 'works with special characters in path' do
      expect(
        described_class.new('/stuff/{range}', path_parameters, use_patterns_for_path_matching)
          .match('/stuff/some..other')
      ).to eq({ 'range' => 'some..other' })
      expect(
        described_class.new('/stuff/{bang}', path_parameters, use_patterns_for_path_matching)
          .match('/stuff/bang!boom!')
      ).to eq({ 'bang' => 'bang!boom!' })
    end

    it 'returns nil without match' do
      expect(
        described_class.new('/{a}/middle/{b}', path_parameters, use_patterns_for_path_matching)
          .match('/1/2/3')
      ).to be_nil
    end

    it 'returns nil when path has more parts' do
      expect(
        described_class.new('/foo/{id}', path_parameters, use_patterns_for_path_matching)
          .match('/foo/middle/bar')
      ).to be_nil
    end

    it 'returns nil when path without variables does not match' do
      expect(
        described_class.new('/a/b', path_parameters, use_patterns_for_path_matching)
          .match('/1/2')
      ).to be_nil
    end

    context 'when using path parameters with patterns' do
      let(:path_parameters) do
        [
          { 'name' => 'foo', 'schema' => { 'pattern' => '^foo$' } },
          { 'name' => 'bar', 'schema' => { 'pattern' => 'bar' } }
        ]
      end

      context 'when use_patterns_for_path_matching is false' do
        let(:use_patterns_for_path_matching) { false }

        it 'matches when the pattern matches' do
          expect(
            described_class.new('/{foo}', path_parameters, use_patterns_for_path_matching)
              .match('/foo')
          ).to eq({ 'foo' => 'foo' })
        end

        it 'matches even though the pattern does not match' do
          expect(
            described_class.new('/{foo}', path_parameters, use_patterns_for_path_matching)
              .match('/bar')
          ).to eq({ 'foo' => 'bar' })
        end
      end

      context 'when use_patterns_for_path_matching is true' do
        let(:use_patterns_for_path_matching) { true }

        it 'matches when the pattern matches' do
          expect(
            described_class.new('/{foo}', path_parameters, use_patterns_for_path_matching)
              .match('/foo')
          ).to eq({ 'foo' => 'foo' })
        end

        it 'does not match when the pattern does not match' do
          expect(
            described_class.new('/{foo}', path_parameters, use_patterns_for_path_matching)
              .match('/bar')
          ).to be_nil
        end

        it 'uses start and end anchors correctly' do
          expect(
            described_class.new('/{foo}', path_parameters, use_patterns_for_path_matching)
              .match('/123foo456')
          ).to be_nil
        end

        it 'uses the lack of start and end anchors correctly' do
          expect(
            described_class.new('/{bar}', path_parameters, use_patterns_for_path_matching)
              .match('/123bar456')
          ).to eq({ 'bar' => '123bar456' })
        end
      end
    end
  end
end

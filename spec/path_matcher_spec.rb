# frozen_string_literal: true

RSpec.describe OpenapiFirst::PathMatcher do
  describe '#call' do
    let(:paths) do
      [
        double(path: '/simple/path'),
        double(path: '/path/with/{variable}')
      ]
    end

    subject(:matcher) { described_class.new(paths) }

    it 'returns the matching object and params' do
      path, params = matcher.call('/simple/path')

      expect(path).to be(paths[0])
      expect(params).to eq({})
    end

    it 'finds a /path/with/{variable}' do
      path, params = matcher.call('/path/with/123')
      expect(path).to be(paths[1])
      expect(params).to eq({ 'variable' => '123' })
    end

    it 'finds a /simple/path' do
      expect(matcher.call('/simple/path')).to eq([paths[0], {}])
    end

    it 'returns nil if no path is found' do
      expect(matcher.call('/path/unknown/123')).to be_nil
    end

    context 'with different variables in common nested routes' do
      let(:paths) do
        [
          double(path: '/foo/{fooId}'),
          double(path: '/foo/special'),
          double(path: '/foo/{id}/bar')
        ]
      end

      it 'finds matches' do
        _, params = subject.call('/foo/1')
        expect(params).to eq({ 'fooId' => '1' })

        _, params = subject.call('/foo/1/bar')
        expect(params).to eq({ 'id' => '1' })

        _, params = subject.call('/foo/special')
        expect(params).to eq({})
      end
    end
  end
end

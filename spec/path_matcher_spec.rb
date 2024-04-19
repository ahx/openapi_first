# frozen_string_literal: true

RSpec.describe OpenapiFirst::PathMatcher do
  describe '#call' do
    let(:paths) do
      [
        '/simple/path',
        '/path/with/{variable}'
      ]
    end

    subject(:matcher) { described_class.new(paths) }

    it 'returns the matching object and params' do
      path, params = matcher.call('/simple/path')

      expect(path).to be(paths[0])
      expect(params).to eq({})
    end

    it 'finds a /path/with/{variable}' do
      expect(matcher.call('/path/with/123')).to eq(['/path/with/{variable}', { 'variable' => '123' }])
    end

    it 'finds a /simple/path' do
      expect(matcher.call('/simple/path')).to eq(['/simple/path', {}])
    end

    it 'returns nil if no path is found' do
      expect(matcher.call('/path/unknown/123')).to be_nil
    end

    context 'with different variables in common nested routes' do
      let(:paths) do
        [
          '/foo/{fooId}',
          '/foo/special',
          '/foo/{id}/bar'
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

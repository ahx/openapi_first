# frozen_string_literal: true

require_relative '../lib/openapi_first/content_matcher'

RSpec.describe OpenapiFirst::ContentMatcher do
  describe '#call' do
    let(:requests) do
      [
        double(content_type: 'application/json'),
        double(content_type: 'application/xml'),
        double(content_type: 'application/json; profile=custom'),
        double(content_type: 'text/*')
      ]
    end

    subject(:matcher) { described_class.new(requests) }

    it 'returns the matching object' do
      expect(matcher.call('application/json')).to eq(requests[0])
    end

    it 'returns empty list if no match' do
      expect(matcher.call('image/*')).to be_nil
    end

    it 'finds an exact match with parameter' do
      exact = 'application/json; profile=custom'
      expect(matcher.call(exact).content_type).to eq(exact)
    end

    it 'finds a match while ignoring parameter' do
      expect(matcher.call('application/xml; Charset=Utf8').content_type).to eq('application/xml')
    end

    it 'finds text/* wildcard matcher' do
      expect(matcher.call('text/markdown; Charset=Utf8').content_type).to eq('text/*')
    end

    it 'finds */* wildcard matcher' do
      requests = [double(content_type: 'application/json'), double(content_type: '*/*')]
      matcher = described_class.new(requests)
      expect(matcher.call('some/foobar').content_type).to eq('*/*')
      expect(matcher.call('some/foobar; Chartset=utf8').content_type).to eq('*/*')
    end
  end
end

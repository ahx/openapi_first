# frozen_string_literal: true

require_relative '../lib/openapi_first/content_matcher'

RSpec.describe OpenapiFirst::ContentMatcher do
  describe '#match' do
    let(:requests) do
      [
        double(content_type: 'application/json'),
        double(content_type: 'application/xml'),
        double(content_type: 'application/json; profile=custom'),
        double(content_type: 'text/*')
      ]
    end

    subject(:matcher) do
      described_class.new.tap do |matcher|
        requests.each do |req|
          matcher.add(req.content_type, req)
        end
      end
    end

    it 'returns the matching object' do
      expect(matcher.match('application/json')).to eq(requests[0])
    end

    it 'returns empty list if no match' do
      expect(matcher.match('image/*')).to be_nil
    end

    it 'finds an exact match with parameter' do
      exact = 'application/json; profile=custom'
      expect(matcher.match(exact).content_type).to eq(exact)
    end

    it 'finds a match while ignoring parameter' do
      expect(matcher.match('application/xml; Charset=Utf8').content_type).to eq('application/xml')
    end

    it 'finds text/* wildcard matcher' do
      expect(matcher.match('text/markdown; Charset=Utf8').content_type).to eq('text/*')
    end

    it 'finds */* wildcard matcher' do
      requests = [double(content_type: 'application/json'), double(content_type: '*/*')]
      matcher = described_class.new.tap do |m|
        requests.each { |req| m.add(req.content_type, req) }
      end
      expect(matcher.match('some/foobar').content_type).to eq('*/*')
      expect(matcher.match('some/foobar; Chartset=utf8').content_type).to eq('*/*')
    end

    it 'finds a match if content_type is not defined' do
      requests = [double(content_type: 'application/json'), double(content_type: nil)]
      matcher = described_class.new.tap do |m|
        requests.each { |req| m.add(req.content_type, req) }
      end
      expect(matcher.match('some/foobar')).to be(requests[1])
    end
  end
end

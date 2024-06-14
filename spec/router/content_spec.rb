# frozen_string_literal: true

RSpec.describe OpenapiFirst::Router::Content do
  describe '#[]' do
    let(:requests) do
      [
        double(content_type: 'application/json'),
        double(content_type: 'application/xml'),
        double(content_type: 'application/json; profile=custom'),
        double(content_type: 'text/*')
      ]
    end

    let(:contents) do
      requests.each_with_object({}) do |req, hash|
        hash[req.content_type] = req
      end
    end

    subject(:matcher) { described_class }

    it 'returns the matching object' do
      expect(matcher.find(contents, 'application/json')).to eq(requests[0])
    end

    it 'returns empty list if no match' do
      expect(matcher.find(contents, 'image/*')).to be_nil
    end

    it 'finds an exact match with parameter' do
      exact = 'application/json; profile=custom'
      expect(matcher.find(contents, exact).content_type).to eq(exact)
    end

    it 'finds a match while ignoring parameter' do
      expect(matcher.find(contents, 'application/xml; Charset=Utf8').content_type).to eq('application/xml')
    end

    it 'finds text/* wildcard matcher' do
      expect(matcher.find(contents, 'text/markdown; Charset=Utf8').content_type).to eq('text/*')
    end

    it 'finds */* wildcard matcher' do
      requests = [double(content_type: 'application/json'), double(content_type: '*/*')]
      contents = requests.each_with_object({}) { |req, m| m[req.content_type] = req }
      expect(matcher.find(contents, 'some/foobar').content_type).to eq('*/*')
      expect(matcher.find(contents, 'some/foobar; Chartset=utf8').content_type).to eq('*/*')
    end

    it 'finds a match if content_type is not defined' do
      requests = [double(content_type: 'application/json'), double(content_type: nil)]
      contents = requests.each_with_object({}) { |req, m| m[req.content_type] = req }
      expect(matcher.find(contents, 'some/foobar')).to be(requests[1])
    end
  end
end

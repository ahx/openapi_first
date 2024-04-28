# frozen_string_literal: true

require_relative '../lib/openapi_first/router'

RSpec.describe OpenapiFirst::Router do
  describe '#match' do
    let(:requests) do
      [
        double(path: '/{id}', request_method: 'get'),
        double(path: '/{id}', request_method: 'patch'),
        double(path: '/a', request_method: 'get')
      ]
    end

    let(:path_items) do
      [
        double(path: '/{id}', requests: { 'GET' => requests[0], 'PATCH' => requests[1] }),
        double(path: '/a', requests: { 'GET' => requests[2] })
      ]
    end

    subject(:router) do
      described_class.new(path_items)
    end

    it 'returns a match with params' do
      match = router.match('PATCH', '/b')
      expect(match.operation).to be(requests[1])
      expect(match.params).to eq('id' => 'b')
      expect(match.error?).to eq(false)
    end

    it 'returns an incomplete match for unknown path' do
      match = router.match('GET', '/c/d')
      expect(match.error?).to eq(true)
      expect(match.error.type).to eq(:not_found)
    end

    it 'returns an incomplete match for unknown request method' do
      match = router.match('DELETE', '/b')
      expect(match.error?).to eq(true)
      expect(match.error.type).to eq(:method_not_allowed)
    end

    pending 'return what methods are allowed for unknown request method' do
      match = router.match('DELETE', '/b')
      expect(match.error.allowed_methods).to eq(%w[GET PATCH])
    end
  end
end

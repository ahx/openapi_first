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

    it 'returns the matching object and params' do
      op, params = router.match('PATCH', '/b')
      expect(op).to be(requests[1])
      expect(params).to eq('id' => 'b')
    end

    it 'returns an incomplete match for unknown path' do
      match, params = router.match('GET', '/c/d')
      expect(match.path).to be_nil
      expect(match.request_method).to be_nil
      expect(match.error?).to eq(true)
      expect(match.error.type).to eq(:not_found)
      expect(params).to be_nil
    end

    it 'returns an incomplete match for unknown request method' do
      match, params = router.match('DELETE', '/b')
      expect(match.path).to eq('/{id}')
      expect(match.request_method).to eq('DELETE')
      expect(match.error?).to eq(true)
      expect(match.error.type).to eq(:method_not_allowed)
      expect(params).to eq('id' => 'b')
    end

    pending 'return what methods are allowed for unknown request method' do
      match, = router.match('DELETE', '/b')
      expect(match.error.allowed_methods).to eq(%w[GET PATCH])
    end
  end
end

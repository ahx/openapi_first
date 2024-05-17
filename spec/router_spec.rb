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

    subject(:router) do
      described_class.new.tap do |router|
        requests.each do |request|
          router.add_route(request.request_method, request.path, request)
        end
      end
    end

    it 'returns a match with params' do
      match = router.match('PATCH', '/b')
      expect(match.operation).to be(requests[1])
      expect(match.params).to eq('id' => 'b')
    end

    it 'returns an incomplete match for unknown path' do
      expect(router.match('GET', '/c/d').error).to have_attributes(error_type: :not_found)
    end

    it 'returns an incomplete match for unknown request method' do
      expect(router.match('DELETE', '/b').error).to have_attributes(error_type: :method_not_allowed)
    end

    pending 'return what methods are allowed for unknown request method' do
      match = router.match('DELETE', '/b')
      expect(match.error.allowed_methods).to eq(%w[GET PATCH])
    end

    context 'with different variables in common nested routes' do
      let(:requests) do
        [
          double(path: '/foo/{fooId}', request_method: 'get'),
          double(path: '/foo/special', request_method: 'get'),
          double(path: '/foo/{id}/bar', request_method: 'get')
        ]
      end

      it 'finds matches' do
        match = router.match('GET', '/foo/1')
        expect(match.params).to eq({ 'fooId' => '1' })

        match = router.match('GET', '/foo/1/bar')
        expect(match.params).to eq({ 'id' => '1' })

        match = router.match('GET', '/foo/special')
        expect(match.params).to eq({})
      end
    end
  end
end

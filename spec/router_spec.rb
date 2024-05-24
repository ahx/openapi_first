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
          router.add_request(request, request_method: request.request_method, path: request.path)
        end
      end
    end

    it 'returns a match with params' do
      match = router.match('PATCH', '/b')
      expect(match.request_definition).to be(requests[1])
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

    context 'with matching content_type' do
      subject(:router) do
        described_class.new.tap do |router|
          router.add_request(1, request_method: 'post', path: '/stations', content_type: 'application/json')
          router.add_request(2, request_method: 'post', path: '/stations', content_type: 'text/*')
        end
      end

      it 'returns a match with matching content-type' do
        match = router.match('POST', '/stations', content_type: 'application/json')
        expect(match.request_definition).to eq(1)

        match = router.match('POST', '/stations', content_type: 'text/html')
        expect(match.request_definition).to eq(2)
      end
    end

    context 'with empty content-type' do
      subject(:router) do
        described_class.new.tap do |router|
          router.add_request(1, request_method: 'post', path: '/stations', content_type: 'application/json')
          router.add_request(2, request_method: 'post', path: '/stations')
        end
      end

      it 'matches with content-type nil' do
        match = router.match('POST', '/stations', content_type: '')
        expect(match.request_definition).to eq(2)

        match = router.match('POST', '/stations', content_type: nil)
        expect(match.request_definition).to eq(2)

        match = router.match('POST', '/stations', content_type: 'application/json')
        expect(match.request_definition).to eq(1)
      end
    end

    context 'without acceptable content-type' do
      subject(:router) do
        described_class.new.tap do |router|
          router.add_request(1, request_method: 'post', path: '/stations', content_type: 'application/xml')
        end
      end

      it 'returns an error' do
        match = router.match('POST', '/stations', content_type: 'application/json')

        message = 'Content-Type application/json is not defined. Content-Type should be application/xml.'
        expect(match.error).to have_attributes(error_type: :unsupported_media_type, message:)
      end
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

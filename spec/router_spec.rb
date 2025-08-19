# frozen_string_literal: true

require_relative '../lib/openapi_first/router'

RSpec.describe OpenapiFirst::Router do
  describe '#match' do
    let(:requests) do
      [
        double(path: '/{id}', request_method: 'get'),
        double(path: '/{id}', request_method: 'patch'),
        double(path: '/a', request_method: 'get'),
        double(path: '/a{format}', request_method: 'get')
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
      expect(router.match('GET', '/c/d').error).to have_attributes(type: :not_found)
    end

    it 'returns a match with only a request method' do
      match = router.match('GET', '/a.json')
      expect(match.request_definition.path).to eq('/a.{format}')
      expect(match.request_definition).to be(requests[3])
    end

    it 'returns an incomplete match for unknown request method' do
      expect(router.match('DELETE', '/b').error).to have_attributes(type: :method_not_allowed)
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
        expect(match.error).to have_attributes(type: :unsupported_media_type, message:)
      end
    end

    context 'with optional request body' do
      subject(:router) do
        described_class.new.tap do |router|
          router.add_request(1, request_method: 'post', path: '/stations', content_type: 'application/json', allow_empty_content: true)
        end
      end

      it 'accepts a matching content_type' do
        match = router.match('POST', '/stations', content_type: 'application/json')
        expect(match.request_definition).to eq(1)
      end

      it 'accepts an empty content_type' do
        match = router.match('POST', '/stations', content_type: nil)
        expect(match.request_definition).to eq(1)
      end

      it 'accepts a content-type mismatch' do
        match = router.match('POST', '/stations', content_type: 'application/xml')
        expect(match.request_definition).to eq(1)
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

    context 'with kebab-case path params' do
      let(:requests) do
        [
          double(path: '/foo/{ke-bab}', request_method: 'get')
        ]
      end
      it 'parses path parameters' do
        match = router.match('GET', '/foo/1')
        expect(match.params).to eq({ 'ke-bab' => '1' })
      end
    end
  end

  describe '#routes' do
    subject(:router) do
      described_class.new.tap do |router|
        router.add_request(:request_get_a, request_method: 'get', path: '/a')
        router.add_request(:request_post_a_json, request_method: 'post', path: '/a', content_type: 'application/json')
        router.add_request(:request_post_a_xml, request_method: 'post', path: '/a', content_type: 'application/xml')

        router.add_response(:response_get_a, request_method: 'get', path: '/a', status: 200)
        router.add_response(:response_post_a_json, request_method: 'post', path: '/a', status: 201, response_content_type: 'application/json')
        router.add_response(:response_post_a_xml, request_method: 'post', path: '/a', status: 201, response_content_type: 'application/xml')

        router.add_request(:request_get_a_id, request_method: 'get', path: '/a/{id}')
      end
    end

    it 'returns all routes' do
      routes = router.routes.to_a
      expect(routes.size).to eq(3)

      get_route = routes[0]
      expect(get_route.requests).to contain_exactly(:request_get_a)
      expect(get_route.responses).to contain_exactly(:response_get_a)
      expect(get_route.request_method).to eq('GET')
      expect(get_route.path).to eq('/a')

      post_route = routes[1]
      expect(post_route.requests).to contain_exactly(:request_post_a_json, :request_post_a_xml)
      expect(post_route.responses).to contain_exactly(:response_post_a_json, :response_post_a_xml)
      expect(post_route.request_method).to eq('POST')
      expect(post_route.path).to eq('/a')

      get_dynamic_route = routes[2]
      expect(get_dynamic_route.requests).to contain_exactly(:request_get_a_id)
      expect(get_dynamic_route.responses.to_a).to be_empty
      expect(get_dynamic_route.request_method).to eq('GET')
      expect(get_dynamic_route.path).to eq('/a/{id}')
    end
  end
end

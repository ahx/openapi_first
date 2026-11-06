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

    it 'can match a path fragment with a variable' do
      match = router.match('GET', '/a.json')
      expect(match.request_definition.path).to eq('/a{format}')
      expect(match.request_definition).to be(requests[3])
    end

    it 'returns an incomplete match for unknown request method' do
      expect(router.match('DELETE', '/b').error).to have_attributes(type: :method_not_allowed)
    end

    it 'does not match a dynamic path with a trailing slash' do
      match = router.match('GET', '/42/')
      expect(match.request_definition).to be_nil
    end

    it 'does not match a static path with a trailing slash' do
      match = router.match('GET', '/a/')
      expect(match.request_definition).to be_nil
    end

    context 'with ambiguous paths' do
      let(:requests) do
        [
          double(path: '/api/{tenant_id}/tickets/extra', request_method: 'get'),
          double(path: '/api/{tenant_id}/tickets/{id}', request_method: 'get')
        ]
      end

      it 'matches the exact path' do
        match = router.match('GET', '/api/42/tickets/extra')
        expect(match.request_definition.path).to eq('/api/{tenant_id}/tickets/extra')
      end
    end

    context 'with trailing slashes in path definitions' do
      let(:requests) do
        [
          double(path: '/{id}/', request_method: 'get'),
          double(path: '/a/', request_method: 'get')
        ]
      end

      it 'matches a dynamic path' do
        match = router.match('GET', '/42/')
        expect(match.request_definition.path).to eq('/{id}/')
      end

      it 'does not match a dynamic path with missing trailing slash' do
        match = router.match('GET', '/42')
        expect(match.error.type).to eq(:not_found)
      end

      it 'matches a static path' do
        match = router.match('GET', '/a/')
        expect(match.request_definition.path).to eq('/a/')
      end

      it 'does not match a static path with missing trailing slash' do
        match = router.match('GET', '/a')
        expect(match.error.type).to eq(:not_found)
      end
    end

    context 'with ambiguous paths reversed' do
      let(:requests) do
        [
          double(path: '/api/{tenant_id}/tickets/{id}', request_method: 'get'),
          double(path: '/api/{tenant_id}/tickets/extra', request_method: 'get')
        ]
      end

      it 'matches the exact path' do
        match = router.match('GET', '/api/42/tickets/extra')
        expect(match.request_definition.path).to eq('/api/{tenant_id}/tickets/extra')
      end
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

    context 'with multiple path params' do
      let(:requests) do
        [
          double(path: '/orgs/{org}/repos/{repo}/issues/{number}', request_method: 'get'),
          double(path: '/orgs/{org}/repos/{repo}', request_method: 'get')
        ]
      end

      it 'parses all path parameters' do
        match = router.match('GET', '/orgs/ivx/repos/api/issues/42')
        expect(match.request_definition).to be(requests[0])
        expect(match.params).to eq({ 'org' => 'ivx', 'repo' => 'api', 'number' => '42' })
      end

      it 'does not match a path with an empty segment' do
        match = router.match('GET', '/orgs//repos/api')
        expect(match.error.type).to eq(:not_found)
      end
    end

    context 'with a variable inside of a segment and a variable for the whole segment' do
      let(:requests) do
        [
          double(path: '/files/{id}', request_method: 'get'),
          double(path: '/files/{name}.{ext}', request_method: 'get')
        ]
      end

      it 'prefers the variable inside of a segment' do
        match = router.match('GET', '/files/report.pdf')
        expect(match.request_definition).to be(requests[1])
        expect(match.params).to eq({ 'name' => 'report', 'ext' => 'pdf' })
      end

      it 'matches the variable for the whole segment' do
        match = router.match('GET', '/files/report')
        expect(match.request_definition).to be(requests[0])
        expect(match.params).to eq({ 'id' => 'report' })
      end
    end

    context 'with multiple variables inside of segments' do
      let(:requests) do
        [
          double(path: '/files/{name}.{ext}', request_method: 'get'),
          double(path: '/files/{name}.json', request_method: 'get'),
          double(path: '/stuff/{a}..{b}', request_method: 'get')
        ]
      end

      it 'prefers the segment with more literal characters' do
        match = router.match('GET', '/files/report.json')
        expect(match.request_definition).to be(requests[1])
        expect(match.params).to eq({ 'name' => 'report' })
      end

      it 'parses all variables of a segment' do
        match = router.match('GET', '/stuff/some..other')
        expect(match.request_definition).to be(requests[2])
        expect(match.params).to eq({ 'a' => 'some', 'b' => 'other' })
      end

      it 'does not match a segment without its literal characters' do
        match = router.match('GET', '/stuff/some.other')
        expect(match.error.type).to eq(:not_found)
      end

      it 'does not match an empty variable inside of a segment' do
        match = router.match('GET', '/files/.json')
        expect(match.error.type).to eq(:not_found)
      end
    end

    context 'with a variable inside of a later segment' do
      let(:requests) do
        [
          double(path: '/{dir}/index.html', request_method: 'get'),
          double(path: '/files/{name}.{ext}', request_method: 'get'),
          double(path: '/files/{id}/{action}', request_method: 'get'),
          double(path: '/files/{id}/{name}.json', request_method: 'get')
        ]
      end

      it 'prefers literal segments from left to right' do
        match = router.match('GET', '/files/index.html')
        expect(match.request_definition).to be(requests[1])
        expect(match.params).to eq({ 'name' => 'index', 'ext' => 'html' })
      end

      it 'prefers the variable inside of a segment over a variable for the whole segment' do
        match = router.match('GET', '/files/1/profile.json')
        expect(match.request_definition).to be(requests[3])
        expect(match.params).to eq({ 'id' => '1', 'name' => 'profile' })
      end

      it 'backtracks to a variable for the whole segment' do
        match = router.match('GET', '/files/1/profile')
        expect(match.request_definition).to be(requests[2])
        expect(match.params).to eq({ 'id' => '1', 'action' => 'profile' })
      end

      it 'backtracks out of a variable inside of a segment' do
        match = router.match('GET', '/files/1.json/profile')
        expect(match.request_definition).to be(requests[2])
        expect(match.params).to eq({ 'id' => '1.json', 'action' => 'profile' })
      end
    end

    context 'with multiple matching templates' do
      let(:requests) do
        [
          double(path: '/{tenant}/settings/profile', request_method: 'get'),
          double(path: '/users/{id}/{action}', request_method: 'get')
        ]
      end

      it 'prefers literal segments from left to right' do
        match = router.match('GET', '/users/settings/profile')
        expect(match.request_definition).to be(requests[1])
        expect(match.params).to eq({ 'id' => 'settings', 'action' => 'profile' })
      end
    end

    context 'with templates that only differ in variable names' do
      let(:requests) do
        [
          double(path: '/items/{id}', request_method: 'get'),
          double(path: '/items/{itemId}', request_method: 'get')
        ]
      end

      it 'matches the template that was added first' do
        match = router.match('GET', '/items/1')
        expect(match.request_definition).to be(requests[0])
        expect(match.params).to eq({ 'id' => '1' })
      end
    end

    context 'with a literal segment that starts with a colon' do
      let(:requests) do
        [
          double(path: '/jobs/{id}/:cancel', request_method: 'post')
        ]
      end

      it 'matches the literal segment' do
        match = router.match('POST', '/jobs/1/:cancel')
        expect(match.params).to eq({ 'id' => '1' })
      end

      it 'does not treat the literal segment as a variable' do
        match = router.match('POST', '/jobs/1/abort')
        expect(match.error.type).to eq(:not_found)
      end
    end

    context 'with percent-encoded path params' do
      let(:requests) do
        [
          double(path: '/files/{name}', request_method: 'get')
        ]
      end

      it 'decodes the params' do
        match = router.match('GET', '/files/my%20file')
        expect(match.params).to eq({ 'name' => 'my file' })
      end

      it 'decodes an encoded slash within its segment' do
        match = router.match('GET', '/files/docs%2Fintro')
        expect(match.params).to eq({ 'name' => 'docs/intro' })
      end

      it 'keeps malformed percent-encodings as they are' do
        match = router.match('GET', '/files/100%zz')
        expect(match.params).to eq({ 'name' => '100%zz' })
      end

      it 'keeps percent-encodings that do not decode to valid UTF-8 as they are' do
        match = router.match('GET', '/files/%FF')
        expect(match.params).to eq({ 'name' => '%FF' })
      end

      it 'keeps percent-encodings that do not decode to valid UTF-8 as they are in a binary path' do
        match = router.match('GET', '/files/%FF'.b)
        expect(match.params).to eq({ 'name' => '%FF' })
      end

      it 'decodes to UTF-8 from a binary path' do
        name = router.match('GET', '/files/%C3%A4'.b).params['name']
        expect(name).to eq('ä')
        expect(name.encoding).to eq(Encoding::UTF_8)
      end
    end
  end

  describe '#match_route' do
    let(:requests) do
      [
        double(path: '/{id}', request_method: 'get'),
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

    it 'uses caller-provided params instead of extracting them from the path' do
      match = router.match_route('GET', '/{id}', params: { 'id' => '42' })
      expect(match.request_definition).to be(requests[0])
      expect(match.params).to eq('id' => '42')
    end

    it 'returns a not_found error for an unknown template' do
      expect(router.match_route('GET', '/unknown', params: {}).error).to have_attributes(type: :not_found)
    end

    it 'returns a method_not_allowed error for an undefined method on a known template' do
      expect(router.match_route('DELETE', '/{id}', params: {}).error).to have_attributes(type: :method_not_allowed)
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

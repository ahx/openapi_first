# frozen_string_literal: true

RSpec.describe OpenapiFirst::RequestParser do
  let(:query_parameters) do
    [
      { 'name' => 'limit', 'in' => 'query', 'schema' => { 'type' => 'integer' } }
    ]
  end

  let(:path_parameters) do
    [
      { 'name' => 'id', 'in' => 'path', 'schema' => { 'type' => 'integer' } }
    ]
  end
  let(:header_parameters) do
    [
      { 'name' => 'X-Api-Key', 'in' => 'header', 'schema' => { 'type' => 'string' } }
    ]
  end
  let(:cookie_parameters) do
    [
      { 'name' => 'session', 'in' => 'cookie', 'schema' => { 'type' => 'string' } }
    ]
  end

  subject(:parser) do
    described_class.new(
      query_parameters:,
      path_parameters:,
      header_parameters:,
      cookie_parameters:,
      content_type: 'application/json'
    )
  end

  let(:rack_request) do
    env = Rack::MockRequest.env_for('/pets/1?limit=3&unknown=4', 'HTTP_X_API_KEY' => 'secret', 'HTTP_COOKIE' => 'session=123', input: JSON.dump({ 'name' => 'Hans' }))
    Rack::Request.new(env)
  end

  describe '#parse' do
    it 'returns all parsed values' do
      parsed = parser.parse(rack_request, route_params: { 'id' => '1' })
      expect(parsed).to have_attributes(
        path: { 'id' => 1 },
        query: { 'limit' => 3 },
        headers: { 'X-Api-Key' => 'secret' },
        cookies: { 'session' => '123' },
        body: { 'name' => 'Hans' }
      )
    end

    context 'when request does not have all parameters' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/pets/1'))
      end

      it 'returns empty values' do
        parsed = parser.parse(rack_request, route_params: { 'id' => '1' })
        expect(parsed).to have_attributes(
          path: { 'id' => 1 },
          query: {},
          headers: {},
          cookies: {},
          body: nil
        )
      end
    end

    context 'when path, header and cookie parameters are not defined' do
      subject(:parser) do
        described_class.new(
          query_parameters:,
          path_parameters: nil,
          header_parameters: nil,
          cookie_parameters: nil,
          content_type: 'application/json'
        )
      end

      it 'does not include other fields' do
        parsed = parser.parse(rack_request, route_params: { 'id' => '1' })
        expect(parsed).to have_attributes(
          query: { 'limit' => 3 },
          body: { 'name' => 'Hans' }
        )
      end
    end

    context 'when content_type is not defined' do
      subject(:parser) do
        described_class.new(
          query_parameters:,
          path_parameters: nil,
          header_parameters: nil,
          cookie_parameters: nil,
          content_type: nil
        )
      end

      it 'does not include the body' do
        parsed = parser.parse(rack_request, route_params: { 'id' => '1' })
        expect(parsed).to have_attributes(
          query: { 'limit' => 3 }
        )
      end
    end

    context 'when JSON body cannot be parsed' do
      let(:rack_request) do
        env = Rack::MockRequest.env_for('/pets/1?limit=3&unknown=4', input: '2%')
        Rack::Request.new(env)
      end

      it 'throws a failure' do
        failure = catch OpenapiFirst::FAILURE do
          parser.parse(rack_request, route_params: { 'id' => '1' })
        end
        expect(failure).to have_attributes(
          type: :invalid_body,
          message: 'Failed to parse request body as JSON'
        )
      end
    end
  end
end

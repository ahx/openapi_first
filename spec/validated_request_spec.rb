# frozen_string_literal: true

RSpec.describe OpenapiFirst::ValidatedRequest do
  let(:path) { nil }
  let(:query) { nil }
  let(:headers) { nil }
  let(:cookies) { nil }
  let(:body) { nil }
  let(:parsed_request) { OpenapiFirst::ParsedRequest.new(path:, query:, headers:, cookies:, body:) }

  let(:valid_request) do
    described_class.new(
      Rack::Request.new(Rack::MockRequest.env_for('/')),
      parsed_request:,
      error: nil,
      request_definition: double(:request_definition)
    )
  end

  let(:invalid_request) do
    described_class.new(
      Rack::Request.new(Rack::MockRequest.env_for('/')),
      error: OpenapiFirst::Failure.new(:invalid_body)
    )
  end

  let(:unknown_request) do
    described_class.new(
      Rack::Request.new(Rack::MockRequest.env_for('/')),
      error: OpenapiFirst::Failure.new(:not_found),
      request_definition: nil
    )
  end

  let(:request_with_values) do
    described_class.new(
      Rack::Request.new(Rack::MockRequest.env_for('/')),
      parsed_request: double(
        path: { 'name' => 42 },
        query: { 'name' => 42 },
        headers: { 'name' => 42 },
        cookies: { 'name' => 42 },
        body: { 'name' => 42 }
      ),
      error: nil
    )
  end

  describe '#valid?' do
    it 'returns true if request is valid' do
      expect(valid_request).to be_valid
    end

    it 'returns false if request is not valid' do
      expect(invalid_request).not_to be_valid
    end
  end

  describe '#invalid?' do
    it 'returns true if request is valid' do
      expect(valid_request).not_to be_invalid
    end

    it 'returns false if request is not valid' do
      expect(invalid_request).to be_invalid
    end
  end

  describe '#known?' do
    it 'returns true if request is known' do
      expect(valid_request).to be_known
    end

    it 'returns false if request is not known' do
      expect(unknown_request).not_to be_known
    end
  end

  describe '#parsed_params' do
    it 'returns merged path, query and body params' do
      parsed_request = double(
        path: { 'winner' => 'path' },
        query: { 'winner' => 'query', 'my-query' => 'query' },
        headers: { 'winner' => 'headers', 'my-header' => 'header' },
        cookies: { 'winner' => 'cookies', 'my-cookie' => 'cookie' },
        body: { 'winner' => 'body', 'my-body' => 'body' }
      )
      request = described_class.new(
        Rack::Request.new(Rack::MockRequest.env_for('/')),
        parsed_request:,
        error: nil
      )
      expect(request.parsed_params).to eq({
                                            'winner' => 'path',
                                            'my-query' => 'query',
                                            'my-body' => 'body'
                                          })
    end

    it 'is empty if no parsed values are given' do
      request = described_class.new(
        Rack::Request.new(Rack::MockRequest.env_for('/')),
        error: nil
      )
      expect(request.parsed_params).to eq({})
    end

    it 'is never empty if one parsed values is not empty' do
      [nil, { 'a' => 'b' }, nil].permutation do |path, query, body|
        request = described_class.new(
          Rack::Request.new(Rack::MockRequest.env_for('/')),
          parsed_request: OpenapiFirst::ParsedRequest.new(path:, query:, body:, headers: nil, cookies: nil),
          error: nil
        )
        expect(request.parsed_params).to eq({ 'a' => 'b' })
      end
    end

    it 'prefers query over body' do
      query = { 'a' => 'b' }
      body = { 'a' => 'frombody' }
      request = described_class.new(
        Rack::Request.new(Rack::MockRequest.env_for('/')),
        parsed_request: OpenapiFirst::ParsedRequest.new(path: nil, query:, body:, headers: nil, cookies: nil),
        error: nil
      )
      expect(request.parsed_params).to eq({ 'a' => 'b' })
    end

    it 'prefers path over query' do
      path = { 'a' => 'b' }
      query = { 'a' => 'fromquery' }
      request = described_class.new(
        Rack::Request.new(Rack::MockRequest.env_for('/')),
        parsed_request: OpenapiFirst::ParsedRequest.new(path:, query:, body: nil, headers: nil, cookies: nil),
        error: nil
      )
      expect(request.parsed_params).to eq({ 'a' => 'b' })
    end
  end

  describe '#parsed_path_parameters' do
    it 'returns the parameters' do
      expect(request_with_values.parsed_path_parameters['name']).to eq(42)
    end
  end

  describe '#parsed_query' do
    it 'returns the parameters' do
      expect(request_with_values.parsed_query['name']).to eq(42)
    end
  end

  describe '#parsed_headers' do
    it 'returns the parameters' do
      expect(request_with_values.parsed_headers['name']).to eq(42)
    end
  end

  describe '#parsed_cookies' do
    it 'returns the parameters' do
      expect(request_with_values.parsed_cookies['name']).to eq(42)
    end
  end

  describe '#parsed_body' do
    it 'returns the parameters' do
      expect(request_with_values.parsed_body['name']).to eq(42)
    end

    it 'can return false' do
      request = described_class.new(
        Rack::Request.new(Rack::MockRequest.env_for('/')),
        parsed_request: double(body: false),
        error: nil
      )
      expect(request.parsed_body).to eq(false)
    end
  end

  describe '#operation_id' do
    it 'returns the operationId value of the operation' do
      request = described_class.new(
        Rack::Request.new(Rack::MockRequest.env_for('/')),
        parsed_request:,
        error: nil,
        request_definition: instance_double(OpenapiFirst::Request, operation_id: 'createPets')
      )
      expect(request.operation_id).to eq('createPets')
    end
  end

  describe '#request_definition' do
    it 'returns the given request_definition' do
      request_definition = double(:request_definition)
      request = described_class.new(
        Rack::Request.new(Rack::MockRequest.env_for('/')),
        parsed_request:,
        error: nil,
        request_definition:
      )
      expect(request.request_definition).to be(request_definition)
    end
  end

  describe '#operation' do
    it 'returns returns the operation object Hash of the Openapi document' do
      operation = { 'operationId' => 'createPets' }
      request = described_class.new(
        Rack::Request.new(Rack::MockRequest.env_for('/')),
        parsed_request:,
        error: nil,
        request_definition: instance_double(OpenapiFirst::Request, operation:)
      )
      expect(request.operation).to be(operation)
    end
  end
end

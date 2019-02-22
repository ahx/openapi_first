require_relative 'spec_helper'
require 'rack'

RSpec.describe OpenapiFirst::ResponseValidator do
  let(:spec) do
    spec_path = './spec/openapi/petstore.yaml'
    OasParser::Definition.resolve(spec_path)
  end

  let(:subject) do
    described_class.new(spec)
  end

  let(:request) do
    env = Rack::MockRequest.env_for('/pets')
    Rack::Request.new(env)
  end

  let(:response_body) do
    JSON.dump({})
  end

  let(:response) do
    headers = { Rack::CONTENT_TYPE => 'application/json' }
    status = 200
    Rack::MockResponse.new(status, headers, response_body)
  end

  it 'returns true' do
    result = subject.validate(request, response)
    expect(result).to eq(true)
  end

  it 'returns false' do
    result = subject.validate(request, response)
    expect(result).to eq(false)
  end
end

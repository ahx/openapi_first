require_relative 'spec_helper'
require 'rack'

RSpec.describe OpenapiFirst::ResponseValidator do
  let(:subject) do
    described_class.new('')
  end

  let(:request) do
    Rack::MockRequest.env_for('/pets')
  end

  let(:response) do
    Rack::Response.new
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

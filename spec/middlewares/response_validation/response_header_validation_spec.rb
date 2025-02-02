# frozen_string_literal: true

require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Response Header validation' do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.app do
      use OpenapiFirst::Middlewares::ResponseValidation, spec: './spec/data/response-header.yaml'
      run(lambda do |env|
        res = Rack::Response.new
        res.status = 201
        res.headers.merge!(JSON.parse(Rack::Request.new(env).body.read))
        res.finish
      end)
    end
  end

  before do
    header Rack::CONTENT_TYPE, 'application/json'
  end

  it 'succeeds with a valid header' do
    post '/echo', JSON.generate({ 'Location' => '/echos/42', 'X-Id' => '42', 'OptionalWithoutSchema' => '432' })
    expect(last_response.status).to eq 201
    expect(last_response.headers['Location']).to eq '/echos/42'
    expect(last_response.headers['X-Id']).to eq '42'
  end

  it 'fails with an invalid header' do
    expect do
      post '/echo', JSON.generate({ 'Location' => '/echos/42', 'X-Id' => 'not-an-integer' })
    end.to raise_error OpenapiFirst::ResponseInvalidError
  end

  it 'ignores "Content-Type" header' do
    post '/echo', JSON.generate({ 'Location' => '/echos/42', 'Content-Type' => 'unknown' })
    expect(last_response.status).to eq 201
  end

  it 'succeeds with a ref in headers scheme' do
    post '/echo', JSON.generate({ 'X-Authors' => 'Frank,Gabriela', 'Location' => '/echos/42' })
    expect(last_response.status).to eq 201
  end

  it 'fails with a ref in headers scheme' do
    expect do
      post '/echo', JSON.generate({ 'X-Authors' => 'A,B,C,D,E', 'Location' => '/echos/42' })
    end.to raise_error OpenapiFirst::ResponseInvalidError
  end

  it 'fails with a missing header' do
    expect do
      post '/echo', JSON.generate({ 'X-Id' => '42' })
    end.to raise_error OpenapiFirst::ResponseInvalidError
  end
end

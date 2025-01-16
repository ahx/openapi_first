# frozen_string_literal: true

require 'rack/test'
require_relative 'spec_helper'
require_relative '../examples/rack_handler'

RSpec.describe 'Example App' do
  include Rack::Test::Methods
  include OpenapiFirst::Test::Methods

  before do
    OpenapiFirst::Test.register(File.join(__dir__, '../examples/openapi.yaml'), as: :example_app)
  end

  def app
    App
  end

  it 'is API conform' do
    get '/'
    assert_api_conform(status: 200, api: :example_app)
  end

  it 'does not explode' do
    get '/'
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq('hello' => 'world')
  end

  it 'returns 404' do
    get '/unknown'
    expect(last_response.status).to eq(404)
  end
end

# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

# frozen_string_literal: true

RSpec.describe OpenapiFirst do
  it 'has a version number' do
    expect(OpenapiFirst::VERSION).not_to be nil
  end

  include Rack::Test::Methods

  module MyApi
    def self.update_pet(_params, _res); end
  end

  SPEC_PATH = './spec/data/petstore-expanded.yaml'

  let(:request_body) do
    {
      'type' => 'pet',
      'attributes' => { 'name' => 'Frido' }
    }
  end

  describe '.app' do
    let(:app) do
      Rack::Builder.app do
        run OpenapiFirst.app(SPEC_PATH, namespace: MyApi)
      end
    end

    before do
      header Rack::CONTENT_TYPE, 'application/json'
    end

    it 'runs the app' do
      patch '/pets/1', json_dump(request_body)

      expect(last_response.status).to eq 200
    end

    it 'returns 404 if path unknown' do
      patch '/unknown', json_dump(request_body)

      expect(last_response.status).to eq 404
    end
  end

  describe '.middleware' do
    let(:app) do
      Rack::Builder.new do
        spec = OpenapiFirst.load(SPEC_PATH)
        use OpenapiFirst.middleware(spec, namespace: MyApi)
        run lambda { |_env|
          Rack::Response.new('hello', 200)
        }
      end
    end

    before do
      header Rack::CONTENT_TYPE, 'application/json'
    end

    it 'runs the app' do
      patch '/pets/1', json_dump(request_body)

      expect(last_response.status).to eq 200
    end

    it 'calls the next app if path is unknown' do
      patch '/unknown', json_dump(request_body)

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'hello'
    end
  end
end

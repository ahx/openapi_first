# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first/rack_responder'

RSpec.describe OpenapiFirst::RackResponder do
  describe '#call' do
    include Rack::Test::Methods

    let(:app) do
      responder = described_class.new(namespace: namespace)
      Rack::Builder.new do
        spec = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')
        use OpenapiFirst::Router, spec: spec
        use Rack::Lint
        run responder
      end
    end

    let(:request_body) do
      {
        'type' => 'people',
        'attributes' => {
          'name' => 'Oscar'
        }
      }
    end

    let(:response_body) do
      json_load(last_response.body, symbolize_keys: true)
    end

    let(:namespace) do
      Module.new do
        def self.find_pets(_env)
          Rack::Response.new.finish
        end
      end
    end

    it 'calls a method on the namespace module' do
      expect(namespace).to receive(:find_pets).and_call_original
      get '/pets'
      expect(last_response.status).to eq 200
    end
  end
end

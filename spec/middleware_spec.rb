# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

# frozen_string_literal: true

RSpec.describe OpenapiFirst do
  include Rack::Test::Methods

  describe '.middleware' do
    let(:app) do
      Rack::Builder.new do
        my_api = Module.new do
          def self.update_pet(_params, _res)
            'updated'
          end
        end

        spec = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')
        use OpenapiFirst.middleware(spec, namespace: my_api)
        run lambda { |_env|
          Rack::Response.new('hello', 200).finish
        }
      end
    end

    before do
      header Rack::CONTENT_TYPE, 'application/json'
    end

    let(:request_body) do
      {
        'type' => 'pet',
        'attributes' => { 'name' => 'Frido' }
      }
    end

    it 'runs the app' do
      patch '/pets/1', json_dump(request_body)

      expect(last_response.body).to eq 'updated'
      expect(last_response.status).to eq 200
    end

    it 'calls the next app if path is unknown' do
      patch '/unknown', json_dump(request_body)

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'hello'
    end
  end
end

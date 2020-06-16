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

    describe 'when handler returns 404' do
      let(:app) do
        Rack::Builder.new do
          my_api = Module.new do
            def self.find_pet(_params, res)
              res.status = 404
              'not found'
            end
          end

          spec = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')
          use OpenapiFirst.middleware(spec, namespace: my_api)
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end

      it 'does not call the next app if handler returns 404' do
        get '/pets/43', json_dump(request_body)

        expect(last_response.status).to eq 404
        expect(last_response.body).to eq 'not found'
      end
    end
  end
end

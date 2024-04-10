# frozen_string_literal: true

require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Cookie Parameter validation' do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.app do
      use OpenapiFirst::Middlewares::RequestValidation,
          spec: File.expand_path('spec/data/cookie-parameter-validation.yaml')
      run lambda { |_env|
        Rack::Response.new('hello', 200).finish
      }
    end
  end

  after do
    clear_cookies
  end

  describe '#call' do
    it 'returns 400 if cookie is invalid' do
      set_cookie 'knusper=quux'
      get '/'

      expect(last_response.status).to eq 400
    end

    it 'adds the converted cookie to env ' do
      set_cookie 'knusper=42'
      get '/'
      expect(last_request.env[OpenapiFirst::REQUEST].cookies['knusper']).to eq 42
    end

    it 'succeeds if cookie is valid' do
      set_cookie 'knusper=42'
      get '/'
      expect(last_response.status).to eq(200), last_response.body
    end

    it 'returns 400 if required cookie is missing' do
      get '/'
      expect(last_response.status).to eq 400
    end

    context 'when raising' do
      let(:app) do
        Rack::Builder.app do
          spec_file = File.expand_path('spec/data/cookie-parameter-validation.yaml')
          use OpenapiFirst::Middlewares::RequestValidation, raise_error: true,
                                                            spec: spec_file
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end

      it 'returns 400 if cookie parameter is invalid' do
        expect do
          get '/'
        end.to raise_error OpenapiFirst::RequestInvalidError, /^Cookie value is invalid: \w+/
      end
    end
  end
end

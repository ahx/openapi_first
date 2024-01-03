# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Cookie Parameter validation' do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.app do
      use OpenapiFirst::RequestValidation, spec: File.expand_path('../data/cookie-parameter-validation.yaml', __dir__)
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
      expect(last_response.status).to be 200
    end

    it 'returns 400 if required cookie is missing' do
      get '/'
      expect(last_response.status).to be 400
    end

    context 'when raising' do
      let(:app) do
        Rack::Builder.app do
          spec_file = File.expand_path('../data/cookie-parameter-validation.yaml', __dir__)
          use OpenapiFirst::RequestValidation, raise_error: true,
                                               spec: spec_file
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end

      it 'returns 400 if cookie parameter is invalid' do
        expect do
          get '/'
        end.to raise_error OpenapiFirst::RequestInvalidError, /^Cookie value invalid: \w+/
      end
    end
  end
end

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
      error = json_load(last_response.body, symbolize_keys: true)[:errors][0]
      expect(error[:title]).to eq 'should be a integer'
      expect(error[:source][:cookie]).to eq 'knusper'
    end

    it 'adds the converted cookie to env ' do
      set_cookie 'knusper=42'
      get '/'
      expect(last_request.env[OpenapiFirst::COOKIES]['knusper']).to eq 42
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
  end
end

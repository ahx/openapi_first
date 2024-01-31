# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe OpenapiFirst::Middlewares::RequestValidation do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.app do
      use Rack::Lint
      use(OpenapiFirst::Middlewares::RequestValidation, spec: File.expand_path('../data/petstore.yaml', __dir__))
      use Rack::Lint
      run lambda { |_env|
        Rack::Response.new('hello', 200).finish
      }
    end
  end

  context 'when request is valid' do
    it 'returns 200' do
      get '/pets?limit=3'

      expect(last_response.status).to eq 200
    end

    it 'adds request to env ' do
      get '/pets'
      expect(last_request.env[OpenapiFirst::REQUEST].operation_id).to eq 'listPets'
    end
  end

  context 'when parameter is invalid' do
    it 'returns 400' do
      get '/pets?limit=three'

      expect(last_response.status).to eq 400
    end
  end

  context 'when request body is invalid JSON' do
    let(:app) do
      Rack::Builder.app do
        use(OpenapiFirst::Middlewares::RequestValidation,
            spec: File.expand_path('../data/petstore-expanded.yaml', __dir__))
        run lambda { |_env|
          Rack::Response.new('hello', 200).finish
        }
      end
    end

    it 'returns 400' do
      header 'Content-Type', 'application/json'
      post '/pets', 'not json'

      expect(last_response.status).to eq 400
    end
  end

  context 'when path is not found' do
    it 'returns 404' do
      get '/unknown'

      expect(last_response.status).to eq 404
    end
  end

  context 'when request method is not found' do
    it 'returns 405' do
      patch '/pets'

      expect(last_response.status).to eq 405
    end
  end

  context 'with custom error_response option' do
    let(:app) do
      custom_class = Class.new do
        include OpenapiFirst::ErrorResponse

        def body = 'custom error body'
        def content_type = 'text/plain'
        def status = 409
      end
      Rack::Builder.app do
        use OpenapiFirst::Middlewares::RequestValidation, spec: './spec/data/request-body-validation.yaml',
                                                          error_response: custom_class
        run lambda { |_env|
          Rack::Response.new('hello', 200).finish
        }
      end
    end

    it 'uses the custom error response' do
      post '/pets'
      expect(last_response.status).to eq 409
      expect(last_response.content_type).to eq 'text/plain'
      expect(last_response.body).to eq 'custom error body'
    end
  end

  context 'with :default error_response option' do
    let(:app) do
      Rack::Builder.app do
        use OpenapiFirst::Middlewares::RequestValidation, spec: './spec/data/request-body-validation.yaml',
                                                          error_response: :default
        run lambda { |_env|
          Rack::Response.new('hello', 200).finish
        }
      end
    end

    it 'returns 400' do
      header 'Content-Type', 'application/json'
      post '/pets'
      expect(last_response.status).to eq 400
    end
  end

  describe '#app' do
    it 'returns the next app in the stack' do
      app = double
      expect(described_class.new(app, spec: File.expand_path('../data/petstore.yaml', __dir__)).app).to eq app
    end
  end
end

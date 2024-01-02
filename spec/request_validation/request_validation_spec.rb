# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe OpenapiFirst::RequestValidation do
  describe '.fail!' do
    it 'throws a failure' do
      expect do
        described_class.fail!(:body)
      end.to throw_symbol(described_class::FAIL, instance_of(described_class::Failure))
    end

    context 'with an unknown argument' do
      it 'throws a failure' do
        expect do
          described_class.fail!(:unknown)
        end.to raise_error(ArgumentError)
      end
    end
  end

  include Rack::Test::Methods
  let(:app) do
    Rack::Builder.app do
      use OpenapiFirst::RequestValidation, spec: './spec/data/parameters.yaml', raise_error: true
      run lambda { |_env|
        Rack::Response.new('hello', 200).finish
      }
    end
  end

  it 'adds request to env ' do
    get '/stuff/12?version=1'
    expect(last_request.env[OpenapiFirst::REQUEST]).to be_a OpenapiFirst::Definition::RuntimeRequest
  end

  context 'with custom error_response option' do
    let(:app) do
      custom_class = Class.new(OpenapiFirst::ErrorResponse) do
        def body = 'custom error body'
        def content_type = 'text/plain'
        def status = 409
      end
      Rack::Builder.app do
        use OpenapiFirst::RequestValidation, spec: './spec/data/request-body-validation.yaml',
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
        use OpenapiFirst::RequestValidation, spec: './spec/data/request-body-validation.yaml', error_response: :default
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
end

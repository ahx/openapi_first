# frozen_string_literal: true

require 'spec_helper'
require 'openapi_first/app'

RSpec.describe OpenapiFirst::App do
  describe '.new' do
    let(:app) do
      namespace = Module.new do
        def self.find_pets(_params, _res); end

        def self.find_pet(_params, _res); end

        def self.create_pet(_params, _res); end

        def self.update_pet(_params, _res); end

        def self.delete_pet(_params, res)
          res.status = 204
        end
      end
      spec = OpenapiFirst.load('./spec/data/petstore-expanded.yaml')
      described_class.new(nil, spec, namespace: namespace, **options)
    end

    describe 'option request_validation_raise_error: true' do
      let(:options) do
        { request_validation_raise_error: true }
      end

      it 'enables raise_error for request_validation' do
        expect(OpenapiFirst::Router).to receive(:new).with(
          anything,
          spec: anything,
          raise_error: false,
          parent_app: anything
        )
        expect(OpenapiFirst::RequestValidation).to receive(:new).with(
          anything,
          raise_error: true
        )
        expect(OpenapiFirst::ResponseValidation).to_not receive(:new)

        app
      end
    end

    describe 'option resolver' do
      let(:my_resolver) { double(:custom_resolver) }

      let(:options) do
        { resolver: my_resolver }
      end

      it 'passes resolver option down to Responder' do
        expect(OpenapiFirst::Responder).to receive(:new).with(
          resolver: my_resolver,
          namespace: anything
        ).and_call_original
        app
      end
    end

    describe 'option router_raise_error: true' do
      let(:options) do
        { router_raise_error: true }
      end

      it 'enables raise_error for router' do
        expect(OpenapiFirst::Router).to receive(:new).with(
          anything,
          spec: anything,
          raise_error: true,
          parent_app: anything
        )
        expect(OpenapiFirst::RequestValidation).to receive(:new).with(
          anything,
          raise_error: false
        )
        expect(OpenapiFirst::ResponseValidation).to_not receive(:new)

        app
      end
    end

    describe 'option response_validation: true' do
      let(:options) do
        { response_validation: true }
      end

      it 'enables response_validation' do
        expect(OpenapiFirst::Router).to receive(:new).with(
          anything,
          spec: anything,
          raise_error: false,
          parent_app: anything
        )
        expect(OpenapiFirst::RequestValidation).to receive(:new).with(
          anything,
          raise_error: false
        )
        expect(OpenapiFirst::ResponseValidation).to receive(:new)

        app
      end
    end
  end
end

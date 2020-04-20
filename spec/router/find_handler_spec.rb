# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'openapi_first/router'

RSpec.describe OpenapiFirst::Router do
  describe '#find_handler' do
    let(:router) do
      described_class.new(
        nil,
        spec: OpenapiFirst.load('./spec/data/petstore.yaml'),
        namespace: Web
      )
    end

    before do
      stub_const(
        'Web',
        Module.new do
          def self.some_method(_params, _res); end
        end
      )
      stub_const(
        'Web::Things',
        Class.new do
          def self.some_class_method(_params, _res); end
        end
      )
      stub_const(
        'Web::Things::Index',
        Class.new do
          def call(_params, _res); end
        end
      )
      stub_const(
        'Web::Things::Show',
        Class.new do
          def initialize(env); end

          def call(_params, _res); end
        end
      )
    end

    let(:env) { double }
    let(:params) { double(:params, env: env) }

    it 'finds some_method' do
      expect(Web).to receive(:some_method)
      router.find_handler('some_method').call
    end

    it 'finds things.some_method' do
      expect(Web::Things).to receive(:some_class_method)
      router.find_handler('things.some_class_method').call
    end

    it 'finds things#index' do
      expect_any_instance_of(Web::Things::Index).to receive(:call)
      router.find_handler('things#index').call(params, double)
    end

    it 'finds things#show with initializer' do
      handler = router.find_handler('things#show')
      response = double
      action = ->(params, res) {}
      expect(Web::Things::Show).to receive(:new).with(env) { action }
      expect(action).to receive(:call).with(params, response)
      handler.call(params, response)
    end

    it 'does not find inherited constants' do
      expect(router.find_handler('string.to_s')).to be_nil
      expect(router.find_handler('::string.to_s')).to be_nil
    end

    it 'does not find nested constants' do
      expect(router.find_handler('foo.bar.to_s')).to be_nil
      expect(router.find_handler('::foo::baz.to_s')).to be_nil
    end
  end
end

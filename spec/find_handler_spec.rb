# frozen_string_literal: true

require 'spec_helper'
require 'rack'
require 'openapi_first/find_handler'

RSpec.describe OpenapiFirst::FindHandler do
  let(:spec) { OpenapiFirst.load('./spec/data/petstore.yaml') }

  let(:subject) do
    described_class.new(
      spec,
      Web
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

  describe '#all' do
    let(:env) { double }
    let(:params) { double(:params, env: env) }
    let(:spec) do
      operation = instance_double(
        OpenapiFirst::Operation,
        operation_id: 'some_method'
      )
      instance_double(OpenapiFirst::Definition, operations: [operation])
    end

    it 'returns a hash with operation_id and handler' do
      expect(Web).to receive(:some_method)
      hash = subject.all
      hash['some_method'].call
    end
  end

  describe '#find_by_operation_id' do
    let(:env) { double }
    let(:params) { double(:params, env: env) }

    it 'finds some_method' do
      expect(Web).to receive(:some_method)
      subject.find_by_operation_id('some_method').call
    end

    it 'finds things.some_method' do
      expect(Web::Things).to receive(:some_class_method)
      subject.find_by_operation_id('things.some_class_method').call
    end

    it 'finds things#index' do
      expect_any_instance_of(Web::Things::Index).to receive(:call)
      subject.find_by_operation_id('things#index').call(params, double)
    end

    it 'finds things#show with initializer' do
      handler = subject.find_by_operation_id('things#show')
      response = double
      action = ->(params, res) {}
      expect(Web::Things::Show).to receive(:new).with(env) { action }
      expect(action).to receive(:call).with(params, response)
      handler.call(params, response)
    end

    it 'does not find inherited constants' do
      expect(subject.find_by_operation_id('string.to_s')).to be_nil
      expect(subject.find_by_operation_id('::string.to_s')).to be_nil
    end

    it 'does not find nested constants' do
      expect(subject.find_by_operation_id('foo.bar.to_s')).to be_nil
      expect(subject.find_by_operation_id('::foo::baz.to_s')).to be_nil
    end
  end
end

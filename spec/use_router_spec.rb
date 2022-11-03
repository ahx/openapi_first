# frozen_string_literal: true

require 'spec_helper'
require 'openapi_first/use_router'

RSpec.describe OpenapiFirst::UseRouter do
  let(:klass) do
    Class.new do
      prepend OpenapiFirst::UseRouter

      def initialize(_app, options)
        @options = options
      end

      def call(_env)
        [200, {}, ['returned by klass']]
      end
    end
  end

  it 'passes all options to Router' do
    options = { my: :options, spec: '' }
    env = {}
    router = instance_double(OpenapiFirst::Router)
    expect(OpenapiFirst::Router).to receive(:new).with(any_args, options) { router }
    expect(router).to receive(:call).with(env)

    instance = klass.new(:app, options)
    instance.call(env)
  end

  it 'calls the superclass call method' do
    env = Rack::MockRequest.env_for('/pets')
    instance = klass.new(:app, { spec: './spec/data/petstore.yaml' })
    response = Rack::Response[*instance.call(env)]
    expect(response.body).to eq ['returned by klass']
  end
end

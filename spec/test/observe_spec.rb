# frozen_string_literal: true

RSpec.describe OpenapiFirst::Test::Observe do
  RSpec.shared_examples 'an observed app' do
    it 'injects request/response validation' do
      described_class.observe(app)

      expect(definition).to receive(:validate_request)
      expect(definition).to receive(:validate_response)

      callable.call(Rack::MockRequest.env_for('/'))
    end
  end

  let(:definition) { OpenapiFirst.load('./examples/openapi.yaml') }
  let(:callable) { app }

  before do
    OpenapiFirst::Test.register(definition)
  end

  context 'with a simple class' do
    let(:app) do
      Class.new do
        def call(_env)
          Rack::Response.new.finish
        end
      end
    end

    let(:callable) { app.new }

    it_behaves_like 'an observed app'

    it 'injects request/response validation only once' do
      2.times { described_class.observe(app) }

      expect(definition).to receive(:validate_request).once
      expect(definition).to receive(:validate_response).once

      callable.call({})
    end
  end

  context 'with a class that has no call method' do
    let(:app) do
      Class.new
    end

    it 'raises an error when trying to observe' do
      expect do
        described_class.observe(app)
      end.to raise_error OpenapiFirst::Test::ObserveError

      app.instance_methods.include?(:call)
    end
  end

  context 'with a Sinatra app' do
    require 'sinatra/base'

    let(:app) do
      Class.new(Sinatra::Base)
    end
    it_behaves_like 'an observed app'

    context 'when using the class method' do
      let(:callable) { app }

      it_behaves_like 'an observed app'
    end
  end

  context 'with a Rails app' do
    require 'rails'
    require 'action_controller/railtie'

    before do
      Rails.logger = Logger.new(StringIO.new)
    end

    let(:app) do
      Class.new(Rails::Application)
    end

    it_behaves_like 'an observed app'
  end

  context 'with a proc' do
    let(:app) do
      ->(_env) { Rack::Response.new.finish }
    end

    it_behaves_like 'an observed app'

    it 'injects request/response validation only once' do
      2.times { described_class.observe(app) }

      expect(definition).to receive(:validate_request).once
      expect(definition).to receive(:validate_response).once

      callable.call({})
    end
  end

  context 'with Rack::Builder.app' do
    let(:app) do
      Rack::Builder.app do
        map '/' do
          run ->(_env) { Rack::Response.new.finish }
        end
      end
    end

    it_behaves_like 'an observed app'
  end
end

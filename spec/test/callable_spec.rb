# frozen_string_literal: true

require 'minitest'

RSpec.describe OpenapiFirst::Test do
  let(:definition) { OpenapiFirst.load('./examples/openapi.yaml') }

  let(:app) do
    Class.new do
      def call(_env)
        Rack::Response.new.finish
      end
    end
  end

  describe 'Callable[]' do
    before do
      require 'openapi_first/test/callable'
    end

    it 'returns a Module that can call the api' do
      mod = described_class::Callable[definition]
      app.prepend(mod)

      expect(definition).to receive(:validate_request)
      expect(definition).to receive(:validate_response)

      app.new.call({})
    end
  end
end

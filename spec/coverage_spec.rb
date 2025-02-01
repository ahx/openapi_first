# frozen_string_literal: true

require_relative '../lib/openapi_first/coverage'

RSpec.describe OpenapiFirst::Coverage do
  let(:filepath) { './spec/data/dice.yaml' }
  let(:definition) { OpenapiFirst.load(filepath) }

  before(:each) do
    described_class.register(filepath)
    described_class.start
  end

  after(:each) do
    described_class.stop
    described_class.reset
  end

  let(:valid_request) { Rack::Request.new(Rack::MockRequest.env_for('/roll', method: 'POST')) }

  let(:valid_response) do
    Rack::Response[200, { 'content-type' => 'application/json' }, ['1']]
  end

  describe '.register' do
    it 'accepts a filepath' do
      filepath = 'spec/data/petstore.yaml'
      expect(described_class.register(filepath)).to be_truthy
      oad = OpenapiFirst.load(filepath)
      expect(described_class.registry[oad.filepath].filepath).to eq(oad.filepath)
    end
  end

  describe '.start' do
    before { described_class.stop }

    it 'accepts a block' do
      myio = StringIO.new
      described_class.start do |config|
        config.output = myio
      end
    end
  end

  describe '.report' do
    def output
      io = StringIO.new
      described_class.report(output: io)
      io.string
    end

    context 'without any requests' do
      specify { expect(output).to include(': 0%') }
    end

    context 'with full coverage' do
      before do
        definition.validate_request(valid_request)
        definition.validate_response(valid_request, valid_response)
      end

      specify { expect(output).to include(': 100%') }
    end

    context 'with partly coverage' do
      before do
        definition.validate_request(valid_request)
      end

      specify { expect(output).to include(': 50%') }
    end
  end
end

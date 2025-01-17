# frozen_string_literal: true

RSpec.describe OpenapiFirst::Test::Coverage do
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
    it 'accepts filepaths' do
      filepath1 = 'spec/data/petstore.yaml'
      filepath2 = 'spec/data/train-travel-api/openapi.yaml'
      expect(described_class.register(filepath1, filepath2)).to be_truthy
      oad1 = OpenapiFirst.load(filepath1)
      oad2 = OpenapiFirst.load(filepath2)
      expect(described_class.registry[oad1.filepath].filepath).to eq(oad1.filepath)
      expect(described_class.registry[oad2.filepath].filepath).to eq(oad2.filepath)
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

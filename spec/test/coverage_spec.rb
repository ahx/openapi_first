# frozen_string_literal: true

RSpec.describe OpenapiFirst::Test::Coverage do
  let(:filepath) { './spec/data/dice.yaml' }
  let(:definition) { OpenapiFirst.load(filepath) }

  before(:each) do
    described_class.install
    OpenapiFirst::Test.register(filepath)
    described_class.start
  end

  after(:each) do
    described_class.uninstall
    described_class.reset
  end

  let(:valid_request) { Rack::Request.new(Rack::MockRequest.env_for('/roll', method: 'POST')) }

  let(:valid_response) do
    Rack::Response[200, { 'content-type' => 'application/json' }, ['1']]
  end

  let(:result) { described_class.result }

  describe '.install' do
    it 'installs global hooks' do
      described_class.install

      hooks = OpenapiFirst.configuration.hooks
      expect(hooks[:after_request_validation]).not_to be_empty
      expect(hooks[:after_response_validation]).not_to be_empty
    end

    it 'does not install hooks multiple times' do
      2.times { described_class.install }

      hooks = OpenapiFirst.configuration.hooks
      expect(hooks[:after_request_validation].count).to eq(1)
      expect(hooks[:after_response_validation].count).to eq(1)
    end
  end

  describe '.result' do
    let(:result) { described_class.result }

    context 'without any requests' do
      specify { expect(result.coverage).to eq(0) }
    end

    context 'with full coverage' do
      before do
        definition.validate_request(valid_request)
        definition.validate_response(valid_request, valid_response)
      end

      specify { expect(result.coverage).to eq(100) }
    end

    context 'with partly coverage' do
      before do
        definition.validate_request(valid_request)
      end

      specify { expect(result.coverage).to eq(50) }
    end
  end

  describe '.track_request' do
    it 'ignores unregistered OADs' do
      oad = double(key: 'unknown')
      described_class.track_request(double, oad)
    end
  end

  describe '.track_response' do
    it 'ignores unregistered OADs' do
      oad = double(key: 'unknown')
      described_class.track_response(double(:response), double(:request), oad)
    end
  end
end

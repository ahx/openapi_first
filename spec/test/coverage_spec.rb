# frozen_string_literal: true

RSpec.describe OpenapiFirst::Test::Coverage do
  let(:filepath) { './spec/data/dice.yaml' }
  let(:definition) { OpenapiFirst.load(filepath) }

  before(:each) do
    OpenapiFirst::Test.register(filepath)
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

  let(:result) { described_class.result }

  describe '.start' do
    after { described_class.stop }

    it 'installs global hooks' do
      hooks = OpenapiFirst.configuration.hooks
      described_class.stop
      expect(hooks[:after_request_validation]).to be_empty
      expect(hooks[:after_response_validation]).to be_empty
      described_class.start
      expect(hooks[:after_request_validation]).not_to be_empty
      expect(hooks[:after_response_validation]).not_to be_empty
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
end

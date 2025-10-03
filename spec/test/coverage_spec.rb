# frozen_string_literal: true

RSpec.describe OpenapiFirst::Test::Coverage do
  let(:definition) do
    OpenapiFirst.parse(YAML.load(%(
      openapi: 3.1.0
      info:
        title: Dice
        version: 1
      paths:
        "/roll":
          post:
            responses:
              '200':
                content:
                  application/json:
                    schema:
                      type: integer
                      min: 1
                      max:
    )))
  end

  before do
    OpenapiFirst::Test.setup do |test|
      test.register(definition)
      test.report_coverage = false
    end
  end

  let(:valid_request) { Rack::Request.new(Rack::MockRequest.env_for('/roll', method: 'POST')) }

  let(:valid_response) do
    Rack::Response[200, { 'content-type' => 'application/json' }, ['1']]
  end

  let(:result) { described_class.result }

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

  describe '.start' do
    before do
      described_class.reset
    end

    it 'starts drb service only once' do
      expect(DRb).to receive(:regist_server).once
      2.times { described_class.start }
    end
  end

  describe '.track_request' do
    it 'ignores unregistered OADs' do
      oad = double(key: 'unknown')
      described_class.track_request(
        double(:request, known?: true, request_definition: double(key: nil), error: nil),
        oad
      )
    end

    it 'ignores unknown requests' do
      request = double(known?: false)
      described_class.track_request(request, definition)
    end

    it 'ignores skipped request' do
      OpenapiFirst::Test.definitions.clear
      OpenapiFirst::Test.setup do |test|
        test.register(definition)
        test.skip_coverage { true }
        test.report_coverage = false
      end

      validated = definition.validate_request(valid_request)
      described_class.track_request(validated, definition)
    end
  end

  describe '.track_response' do
    it 'ignores unregistered OADs' do
      oad = double(key: 'unknown')
      described_class.track_response(
        double(:response, known?: true, response_definition: double(key: nil), error: nil),
        double(:request),
        oad
      )
    end

    it 'ignores unknown response' do
      response = double(known?: false)
      described_class.track_response(response, double(:request), definition)
    end
  end
end

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

  describe '.track_request' do
    it 'ignores unregistered OADs' do
      oad = double(key: 'unknown')
      described_class.track_request(double, oad)
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
      described_class.track_response(double(:response), double(:request), oad)
    end
  end
end

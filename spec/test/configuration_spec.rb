# frozen_string_literal: true

RSpec.describe OpenapiFirst::Test::Configuration do
  subject(:configuration) { described_class.new }

  describe '#handle_exit' do
    it 'reports coverage and fails' do
      expect(OpenapiFirst::Test).to receive(:report_coverage)
      expect do
        configuration.handle_exit
      end.to raise_error(SystemExit)
    end

    it 'raises an error with invalid option value' do
      expect do
        configuration.report_coverage = :fatal
      end.to raise_error(ArgumentError)
    end

    context 'with full coverage' do
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
        valid_request = Rack::Request.new(Rack::MockRequest.env_for('/roll', method: 'POST'))
        valid_response = Rack::Response[200, { 'content-type' => 'application/json' }, ['1']]
        OpenapiFirst::Test.setup { |test| test.register(definition) }
        definition.validate_request(valid_request)
        definition.validate_response(valid_request, valid_response)
      end

      it 'reports coverage but does not fail' do
        expect(OpenapiFirst::Test).to receive(:report_coverage)

        expect do
          configuration.handle_exit
        end.not_to raise_error(SystemExit)
      end
    end

    context 'with report_coverage = true' do
      before do
        configuration.report_coverage = true
      end

      it 'reports coverage' do
        expect(OpenapiFirst::Test).to receive(:report_coverage)
        expect do
          configuration.handle_exit
        end.to raise_error(SystemExit)
      end
    end

    context 'with report_coverage = false' do
      before do
        configuration.report_coverage = false
      end

      it 'does not report coverage' do
        expect(OpenapiFirst::Test).not_to receive(:report_coverage)

        configuration.handle_exit
      end
    end

    context 'with report_coverage = :warn' do
      before do
        configuration.report_coverage = :warn
      end

      it 'reports coverage, but does not fail' do
        expect(OpenapiFirst::Test).to receive(:report_coverage)

        configuration.handle_exit
      end
    end
  end
end

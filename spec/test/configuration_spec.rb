# frozen_string_literal: true

RSpec.describe OpenapiFirst::Test::Configuration do
  subject(:configuration) { described_class.new }

  it 'raises an error with invalid option value' do
    expect do
      configuration.report_coverage = :fatal
    end.to raise_error(ArgumentError)
  end

  describe 'ignored_unknown_status' do
    it 'has a default value' do
      expect(configuration.ignored_unknown_status).to eq [404]
    end

    it 'can be extended' do
      configuration.ignored_unknown_status << 401
      expect(configuration.ignored_unknown_status).to eq [404, 401]
    end
  end

  describe '#ignore_response?' do
    let(:valid_response) { double(valid?: true, known?: true, status: 302) }
    let(:invalid_response) { double(valid?: false, known?: true, status: 302) }
    let(:unknown_response) { double(valid?: false, known?: false, status: 302) }

    it 'returns false by default for a valid responses' do
      expect(configuration.ignore_response?(valid_response)).to eq(false)
    end

    it 'returns false by default for an invalid responses' do
      expect(configuration.ignore_response?(invalid_response)).to eq(false)
    end

    it 'returns false by default for an unkonwn responses' do
      expect(configuration.ignore_response?(unknown_response)).to eq(false)
    end

    context 'when status is ignored' do
      before { configuration.ignored_unknown_status << invalid_response.status }

      it 'returns true' do
        expect(configuration.ignore_response?(invalid_response)).to eq(true)
      end
    end

    context 'when all responses are ignored' do
      before { configuration.ignore_unknown_responses = true }

      it 'returns true' do
        expect(configuration.ignore_response?(invalid_response)).to eq(true)
      end
    end
  end
end

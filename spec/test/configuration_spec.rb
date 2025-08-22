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
    let(:unknown_response_status) { double(valid?: false, known?: false, status: 302, error: OpenapiFirst::Failure.new(:response_status_not_found)) }

    it 'returns false by default for a valid responses' do
      expect(configuration.ignore_response?(valid_response)).to eq(false)
    end

    it 'returns false by default for an invalid responses' do
      expect(configuration.ignore_response?(invalid_response)).to eq(false)
    end

    it 'returns false by default for an unkonwn responses' do
      expect(configuration.ignore_response?(unknown_response_status)).to eq(false)
    end

    context 'when status is ignored' do
      before { configuration.ignored_unknown_status << unknown_response_status.status }

      it 'returns true for an unknown response with that status' do
        expect(configuration.ignore_response?(unknown_response_status)).to eq(true)
      end

      it 'returns false for an unknown response with another status' do
        unknown_response_status = double(valid?: false, known?: false, status: 409)
        expect(configuration.ignore_response?(unknown_response_status)).to eq(false)
      end
    end

    context 'when all unknown response status are ignored' do
      before { configuration.ignore_all_unknown_response_status = true }

      it 'returns true for any unknown response status' do
        expect(configuration.ignore_response?(unknown_response_status)).to eq(true)
      end

      it 'returns false for an unknown response with a known status' do
        unknown_response_content_type = double(valid?: false, known?: false, status: 302, error: OpenapiFirst::Failure.new(:response_content_type_not_found))

        expect(configuration.ignore_response?(unknown_response_content_type)).to eq(false)
      end
    end
  end
end

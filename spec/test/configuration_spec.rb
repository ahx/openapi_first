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
      expect(configuration.ignored_unknown_status).to contain_exactly(401, 404, 500)
    end

    it 'can be extended' do
      configuration.ignored_unknown_status << 401
      expect(configuration.ignored_unknown_status).to include(401)
    end
  end

  describe '#raise_response_error?' do
    let(:valid_response) { double(valid?: true, unknown?: false, status: 302) }
    let(:invalid_response) { double(valid?: false, unknown?: false, status: 302) }
    let(:unknown_response_status) { double(valid?: false, unknown?: true, status: 302, error: OpenapiFirst::Failure.new(:response_status_not_found)) }
    let(:rack_request) { Rack::Request.new({}) }

    it 'returns true by default for valid responses' do
      expect(configuration.raise_response_error?(valid_response, rack_request)).to eq(true)
    end

    it 'returns true by default for invalid responses' do
      expect(configuration.raise_response_error?(invalid_response, rack_request)).to eq(true)
    end

    it 'returns true by default for unkonwn responses' do
      expect(configuration.raise_response_error?(unknown_response_status, rack_request)).to eq(true)
    end

    context 'when status is ignored' do
      before { configuration.ignored_unknown_status << unknown_response_status.status }

      it 'returns false for an unknown response with that status' do
        expect(configuration.raise_response_error?(unknown_response_status, rack_request)).to eq(false)
      end

      it 'returns true for an unknown response with another status' do
        unknown_response_status = double(valid?: false, unknown?: true, status: 409, error: OpenapiFirst::Failure.new(:response_status_not_found))
        expect(configuration.raise_response_error?(unknown_response_status, rack_request)).to eq(true)
      end
    end

    context 'when all unknown response status are ignored' do
      before { configuration.ignore_unknown_response_status = true }

      it 'returns false for any unknown response status' do
        expect(configuration.raise_response_error?(unknown_response_status, rack_request)).to eq(false)
      end

      it 'returns true for an unknown response with a known status' do
        unknown_response_content_type = double(valid?: false, unknown?: true, status: 302, error: OpenapiFirst::Failure.new(:response_content_type_not_found))

        expect(configuration.raise_response_error?(unknown_response_content_type, rack_request)).to eq(true)
      end
    end
  end
end

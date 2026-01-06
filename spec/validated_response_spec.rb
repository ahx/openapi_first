# frozen_string_literal: true

RSpec.describe OpenapiFirst::ValidatedResponse do
  describe '#parsed_body' do
    it 'returns nil without parsed values' do
      validated = described_class.new(double(:request), error: double(:error))
      expect(validated.parsed_body).to be_nil
    end
  end

  describe '#parsed_headers' do
    it 'returns nil without parsed values' do
      validated = described_class.new(double(:request), error: double(:error))
      expect(validated.parsed_headers).to be_nil
    end
  end

  describe '#known?' do
    it 'returns false if response is unknown' do
      unknown_response = described_class.new(double(:response), error: double(:error))
      expect(unknown_response).not_to be_known
    end

    it 'returns true if response is known' do
      valid_response = described_class.new(double(:response), error: nil, response_definition: double(:response_definition))
      expect(valid_response).to be_known
    end
  end

  describe '#unknown?' do
    it 'returns true if response is unknown' do
      unknown_response = described_class.new(double(:response), error: double(:error))
      expect(unknown_response).to be_unknown
    end

    it 'returns false if response is known' do
      valid_response = described_class.new(double(:response), error: nil, response_definition: double(:response_definition))
      expect(valid_response).not_to be_unknown
    end
  end
end

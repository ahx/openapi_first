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
end

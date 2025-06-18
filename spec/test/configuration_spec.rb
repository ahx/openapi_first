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
end

# frozen_string_literal: true

RSpec.describe OpenapiFirst::Test::Configuration do
  subject(:configuration) { described_class.new }

  it 'raises an error with invalid option value' do
    expect do
      configuration.report_coverage = :fatal
    end.to raise_error(ArgumentError)
  end
end

# frozen_string_literal: true

RSpec.describe OpenapiFirst::Failure do
  describe '.fail!' do
    it 'throws a failure' do
      expect do
        described_class.fail!(:invalid_body)
      end.to throw_symbol(described_class::FAILURE, instance_of(described_class))
    end

    context 'with an unknown argument' do
      it 'throws a failure' do
        expect do
          described_class.fail!(:unknown)
        end.to raise_error(ArgumentError)
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe OpenapiFirst::Failure do
  describe '.fail!' do
    it 'throws a failure' do
      expect do
        described_class.fail!(:invalid_body)
      end.to throw_symbol(OpenapiFirst::FAILURE, instance_of(described_class))
    end

    context 'with an unknown argument' do
      it 'throws a failure' do
        expect do
          described_class.fail!(:unknown)
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe '#message' do
    it 'returns a generated message if not defined' do
      failure = described_class.new(:invalid_body, errors: [double(error: 'something is wrong')])
      expect(failure.message).to eq('Request body invalid: something is wrong')
    end

    it 'returns the specified message' do
      failure = described_class.new(:invalid_body, message: 'custom message')
      expect(failure.message).to eq('custom message')
    end

    context 'with a lot of errors' do
      let(:failure) do
        errors = Array.new(100) do |i|
          instance_double(OpenapiFirst::Schema::ValidationError, error: "something is wrong over there #{i}")
        end
        described_class.new(:invalid_body, errors:)
      end

      it 'returns a reduced message' do
        expect(failure.message).to eq(
          'Request body invalid: something is wrong over there 0. something is wrong over there 1. ' \
          'something is wrong over there 2. ... (100 errors total)'
        )
      end
    end
  end

  describe '#type' do
    it 'returns the error type' do
      expect(described_class.new(:invalid_body).type).to eq(:invalid_body)
    end
  end

  describe '#type' do
    it 'returns the error type' do
      expect(described_class.new(:invalid_body).type).to eq(:invalid_body)
    end
  end

  describe '#exception' do
    it 'returns an exception' do
      exception = described_class.new(:invalid_body).exception
      expect(exception).to be_a(OpenapiFirst::RequestInvalidError)
    end

    context 'with a lot of errors' do
      let(:failure) do
        errors = Array.new(100) do |i|
          instance_double(OpenapiFirst::Schema::ValidationError, error: "something is wrong over there #{i}")
        end
        described_class.new(:invalid_body, errors:)
      end

      it 'raises an error with a reduced message' do
        expect(failure.exception.message).to eq(
          'Request body invalid: something is wrong over there 0. something is wrong over there 1. ' \
          'something is wrong over there 2. ... (100 errors total)'
        )
      end
    end
  end
end

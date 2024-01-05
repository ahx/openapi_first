# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe OpenapiFirst::RequestValidation do
  describe '.fail!' do
    it 'throws a failure' do
      expect do
        described_class.fail!(:invalid_body)
      end.to throw_symbol(described_class::FAILURE, instance_of(described_class::Failure))
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

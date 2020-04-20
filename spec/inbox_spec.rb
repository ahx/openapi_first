# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenapiFirst::Inbox do
  it 'behaves like a hash' do
    params = described_class.new(:fake_env)

    params.merge!(existing: :value)
    params['existing'] = 'other_value'

    expect(params[:existing]).to eq :value
    expect(params['existing']).to eq 'other_value'
  end

  it 'returns nil on non-existant keys' do
    params = described_class.new(:fake_env)
    expect(params[:non_existing]).to be_nil
  end

  it 'has an env' do
    params = described_class.new(:fake_env)
    expect(params.env).to eq :fake_env
  end
end

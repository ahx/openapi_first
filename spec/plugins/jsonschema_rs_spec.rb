# frozen_string_literal: true

require 'openapi_first/plugins/jsonschema_rs'

RSpec.describe OpenapiFirst::Plugins::JsonschemaRs do
  around do |example|
    previous = OpenapiFirst.configuration.schema_backend
    example.run
  ensure
    OpenapiFirst.configuration.schema_backend = previous
  end

  it 'sets the global schema backend when enabled via OpenapiFirst.plugin' do
    OpenapiFirst.plugin :jsonschema_rs
    expect(OpenapiFirst.schema_backend).to eq(OpenapiFirst::Schema::JsonschemaRsBackend)
  end

  it 'can be enabled via OpenapiFirst.configure' do
    OpenapiFirst.configure { |config| config.plugin :jsonschema_rs }
    expect(OpenapiFirst.schema_backend).to eq(OpenapiFirst::Schema::JsonschemaRsBackend)
  end

  it 'raises when enabled per definition because the backend is global' do
    spec = { 'openapi' => '3.1.0', 'info' => { 'title' => 't', 'version' => '1' }, 'paths' => {} }
    expect do
      OpenapiFirst.parse(spec) { |config| config.plugin :jsonschema_rs }
    end.to raise_error(ArgumentError, /global/)
  end
end

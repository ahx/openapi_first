# frozen_string_literal: true

RSpec.describe OpenapiFirst::Plugins do
  def build_request(path, method: 'GET')
    Rack::Request.new(Rack::MockRequest.env_for(path, method:))
  end

  after { OpenapiFirst.instance_variable_set(:@configuration, nil) }

  let(:spec) do
    {
      'openapi' => '3.1.0',
      'info' => { 'title' => 'Test', 'version' => '1' },
      'paths' => {
        '/public' => {
          'get' => {
            'x-public' => true,
            'responses' => { '200' => { 'description' => 'ok' } }
          }
        },
        '/private' => {
          'get' => {
            'responses' => { '200' => { 'description' => 'ok' } }
          }
        }
      }
    }
  end

  it 'raises ArgumentError when a plugin does not respond to .configure' do
    stub_const('OpenapiFirst::Plugins::Bad', Module.new)
    expect do
      OpenapiFirst.parse(spec) { |c| c.plugin :bad }
    end.to raise_error(ArgumentError, /must respond to .configure/)
  end

  context 'when loaded globally' do
    it 'applies to all definitions' do
      OpenapiFirst.plugin :x_public
      definition = OpenapiFirst.parse(spec)

      expect(definition.validate_request(build_request('/public'))).to be_valid
      expect(definition.validate_request(build_request('/private'))).to be_invalid
    end
  end

  context 'when loaded locally' do
    it 'applies to only this one definition' do
      with_plugin = OpenapiFirst.parse(spec) { |oad| oad.plugin :x_public }
      without_plugin = OpenapiFirst.parse(spec)

      expect(without_plugin.validate_request(build_request('/private'))).to be_valid
      expect(with_plugin.validate_request(build_request('/private'))).to be_invalid
    end
  end
end

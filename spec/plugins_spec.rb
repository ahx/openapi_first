# frozen_string_literal: true

RSpec.describe OpenapiFirst::Plugins do
  def build_request(path, method: 'GET')
    Rack::Request.new(Rack::MockRequest.env_for(path, method:))
  end

  after { OpenapiFirst.instance_variable_set(:@configuration, nil) }

  it 'raises ArgumentError when a plugin does not respond to .configure' do
    stub_const('OpenapiFirst::Plugins::Bad', Module.new)
    expect do
      OpenapiFirst.plugin :bad
    end.to raise_error(ArgumentError, /must respond to .configure/)
  end

  context 'when loaded globally' do
    it 'applies to all definitions' do
      OpenapiFirst.plugin :x_public
      definition = OpenapiFirst.load('spec/data/x-public.yaml')

      expect(definition.validate_request(build_request('/public'))).to be_valid
      expect(definition.validate_request(build_request('/private'))).to be_invalid
    end
  end

  context 'when loaded locally' do
    it 'applies to this one definition' do
      with_public = OpenapiFirst.load('spec/data/x-public.yaml') { |c| c.plugin :x_public }
      without_public = OpenapiFirst.load('spec/data/x-public.yaml')

      expect(with_public.validate_request(build_request('/private'))).to be_invalid
      expect(without_public.validate_request(build_request('/private'))).to be_valid
    end
  end

  context 'when loaded via register' do
    it 'applies to this one definition' do
      with_plugin = OpenapiFirst.register('spec/data/x-public.yaml') { |api| api.plugin :x_public }

      expect(with_plugin.validate_request(build_request('/private'))).to be_invalid
    end
  end
end

# frozen_string_literal: true

RSpec.describe OpenapiFirst::Configuration do
  describe '#after' do
    it 'adds a hook' do
      config = OpenapiFirst::Configuration.new
      config.after_request_validation do |request|
        request
      end

      expect(config.hooks[:after_request_validation].size).to eq(1)
    end

    it 'adds multiple actions' do
      config = OpenapiFirst::Configuration.new
      config.after_request_validation do |request|
        request
      end
      config.after_request_validation do |request|
        request
      end

      expect(config.hooks[:after_request_validation].size).to eq(2)
    end
  end

  describe '#call_hook' do
    it 'calls the configured action' do
      config = OpenapiFirst::Configuration.new
      config.after_request_validation do |request|
        request
      end

      expect(config.call_hook(:after_request_validation, 'request')).to eq(['request'])
    end

    it 'does nothing if no hook is setup' do
      config = OpenapiFirst::Configuration.new
      expect(config.call_hook(:after_request_validation, 'request')).to be_nil
    end
  end

  describe '#clone' do
    it 'clones actions' do
      config = OpenapiFirst::Configuration.new
      config.after_request_validation { |request| request }
      expect(config.hooks[:after_request_validation].size).to eq(1)
      cloned = config.clone
      cloned.after_request_validation { |request| request }
      expect(cloned.hooks[:after_request_validation].size).to eq(2)
      expect(config.hooks[:after_request_validation].size).to eq(1)
    end

    it 'clones empty configs' do
      config = OpenapiFirst::Configuration.new
      expect(config.hooks).to eq(nil)
      cloned = config.clone
      expect(cloned.hooks).to eq(nil)
    end
  end
end

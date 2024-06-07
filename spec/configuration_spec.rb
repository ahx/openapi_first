# frozen_string_literal: true

RSpec.describe OpenapiFirst::Configuration do
  describe '#after' do
    it 'adds a hook' do
      config = OpenapiFirst::Configuration.new
      called = []
      config.after_request_validation do |request|
        called << request
      end

      config.hooks[:after_request_validation].each { |hook| hook.call('request') }
      expect(called).to eq(%w[request])
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

  describe '#request_validation_raise_error' do
    specify do
      expect(OpenapiFirst.configuration.request_validation_raise_error).to be(false)
    end

    it 'can be set to true' do
      config = OpenapiFirst::Configuration.new
      config.request_validation_raise_error = true
      expect(config.request_validation_raise_error).to be(true)
    end
  end

  describe '#response_validation_raise_error' do
    specify do
      expect(OpenapiFirst.configuration.response_validation_raise_error).to be(true)
    end

    it 'can be set to false' do
      config = OpenapiFirst::Configuration.new
      config.response_validation_raise_error = false
      expect(config.response_validation_raise_error).to be(false)
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
      expect(config.hooks.values.all?(&:empty?)).to be(true)
      cloned = config.clone
      expect(cloned.hooks.values.all?(&:empty?)).to be(true)
    end
  end
end

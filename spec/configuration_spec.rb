# frozen_string_literal: true

RSpec.describe OpenapiFirst::Configuration do
  describe '#after' do
    it 'adds a hook' do
      config = OpenapiFirst::Configuration.new
      called = []
      config.after_request_validation do |request|
        called << request
      end

      config.hooks[:after_request_validation]&.each { |hook| hook.call('request') }
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
      expect(config.hooks).to be_empty
      cloned = config.clone
      expect(cloned.hooks).to be_empty
    end
  end
end

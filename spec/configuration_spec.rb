# frozen_string_literal: true

RSpec.describe OpenapiFirst::Configuration do
  describe '#after_...' do
    it 'adds a hook' do
      config = OpenapiFirst::Configuration.new
      called = []
      config.after_request_validation do |request|
        called << request
      end

      config.after_request_validation.each { |hook| hook.call('request') }
      expect(called).to eq(%w[request])
    end

    it 'adds multiple actions' do
      config = OpenapiFirst::Configuration.new
      config.after_request_validation { _1 }
      config.after_request_validation { _1 }

      expect(config.after_request_validation.size).to eq(2)
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

  describe '#request_validation_error_response=' do
    it 'sets the error response' do
      config = OpenapiFirst::Configuration.new
      config.request_validation_error_response = :jsonapi
      expect(config.request_validation_error_response).to be(OpenapiFirst::ErrorResponses::Jsonapi)
    end
  end

  describe '#child' do
    it 'clones actions' do
      config = OpenapiFirst::Configuration.new
      config.after_request_validation { |request| request }
      expect(config.after_request_validation.size).to eq(1)
      cloned = config.child
      cloned.after_request_validation { |request| request }
      expect(cloned.after_request_validation.size).to eq(2)
      expect(config.after_request_validation.size).to eq(1)
    end

    it 'clones empty configs' do
      config = OpenapiFirst::Configuration.new
      expect(config.after_request_validation.to_a).to be_empty
      cloned = config.child
      expect(cloned.after_request_validation.to_a).to be_empty
    end

    it 'allows adding hooks to the parent config after cloning' do
      parent = OpenapiFirst::Configuration.new
      parent.after_request_validation { |request| request }

      child = parent.child

      expect(child.after_request_validation.size).to eq(1)
      parent.after_request_validation { |request| request }
      expect(parent.after_request_validation.size).to eq(2)
      expect(child.after_request_validation.size).to eq(2)
    end
  end
end

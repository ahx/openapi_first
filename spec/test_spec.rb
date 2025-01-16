# frozen_string_literal: true

require 'minitest'

RSpec.describe OpenapiFirst::Test do
  describe '.minitest?' do
    it 'detects minitest' do
      test_case = Class.new(Minitest::Test)
      expect(described_class.minitest?(test_case)).to be(true)
      expect(described_class.minitest?(Class.new)).to be(false)
      expect(described_class.minitest?(self.class)).to be(false)
    end
  end

  describe '.register' do
    it 'registers an OAD as :default by default' do
      described_class.register('./examples/openapi.yaml')
      expect(described_class[:default].filepath).to eq('./examples/openapi.yaml')
    end

    it 'can register an OAD with a custom name' do
      described_class.register('./examples/openapi.yaml', as: :mine)
      expect(described_class[:mine].filepath).to eq('./examples/openapi.yaml')
    end
  end

  describe '.[]' do
    it 'complaints about an unknown api' do
      expect do
        described_class[:mine]
      end.to raise_error(OpenapiFirst::Test::NotRegisteredError)
    end
  end

  describe 'Methods' do
    it 'can be included' do
      minitest_class = Class.new(Minitest::Test) do
        include OpenapiFirst::Test::Methods
      end
      expect(minitest_class.included_modules).to include(described_class::MinitestHelpers)

      other_class = Class.new do
        include OpenapiFirst::Test::Methods
      end
      expect(other_class.included_modules).to include(described_class::PlainHelpers)
    end

    it 'detects wrong response status for Minitest' do
      described_class.register('./examples/openapi.yaml')
      minitest_class = Class.new(Minitest::Test) do
        include OpenapiFirst::Test::Methods

        def last_request = Rack::Request.new(Rack::MockRequest.env_for('/'))
        def last_response = Rack::Response.new
      end

      expect do
        minitest_class.new('hey').assert_api_conform(status: 444)
      end.to raise_error(Minitest::Assertion)
    end

    it 'detects wrong response status for non Minitest' do
      described_class.register('./examples/openapi.yaml')
      minitest_class = Class.new do
        include OpenapiFirst::Test::Methods

        def last_request = Rack::Request.new(Rack::MockRequest.env_for('/'))
        def last_response = Rack::Response.new
      end

      expect do
        minitest_class.new.assert_api_conform(status: 444)
      end.to raise_error(OpenapiFirst::Error)
    end
  end
end

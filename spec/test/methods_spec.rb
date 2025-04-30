# frozen_string_literal: true

require 'minitest'

RSpec.describe OpenapiFirst::Test::Methods do
  it 'can be included' do
    minitest_class = Class.new(Minitest::Test) do
      include OpenapiFirst::Test::Methods
    end
    expect(minitest_class.included_modules).to include(OpenapiFirst::Test::MinitestHelpers)

    other_class = Class.new do
      include OpenapiFirst::Test::Methods
    end
    expect(other_class.included_modules).to include(OpenapiFirst::Test::PlainHelpers)
  end

  it 'adds an app method that wraps the app' do
    OpenapiFirst::Test.register('./examples/openapi.yaml')
    myapp = ->(_env) { Rack::Response.new('hello').finish }
    minitest_class = Class.new(Minitest::Test) do
      include OpenapiFirst::Test::Methods[myapp]
    end
    expect(minitest_class.included_modules).to include(OpenapiFirst::Test::MinitestHelpers)

    test_app = minitest_class.new(1).app
    env = Rack::MockRequest.env_for('/')
    expect(test_app.call(env)).to eq(Rack::Response.new('hello').finish)
    expect(env[OpenapiFirst::REQUEST]).to be_valid
  end

  it 'adds an app method that wraps the app for a specific API' do
    OpenapiFirst::Test.register('./examples/openapi.yaml', as: :v1)
    myapp = ->(_env) { Rack::Response.new('hello').finish }
    minitest_class = Class.new(Minitest::Test) do
      include OpenapiFirst::Test::Methods[myapp, api: :v1]
    end
    expect(minitest_class.included_modules).to include(OpenapiFirst::Test::MinitestHelpers)

    test_app = minitest_class.new(1).app
    env = Rack::MockRequest.env_for('/')
    expect(test_app.call(env)).to eq(Rack::Response.new('hello').finish)
    expect(env[OpenapiFirst::REQUEST]).to be_valid
  end

  it 'does not add an app method if app is nil' do
    OpenapiFirst::Test.register('./examples/openapi.yaml', as: :v1)
    minitest_class = Class.new(Minitest::Test) do
      include OpenapiFirst::Test::Methods[api: :v1]
    end
    expect(minitest_class.included_modules).to include(OpenapiFirst::Test::MinitestHelpers)

    expect(minitest_class.new(1).respond_to?(:app)).to eq(false)
  end

  it 'detects wrong response status for Minitest' do
    OpenapiFirst::Test.register('./examples/openapi.yaml')
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
    OpenapiFirst::Test.register('./examples/openapi.yaml')
    other_test_class = Class.new do
      include OpenapiFirst::Test::Methods

      def last_request = Rack::Request.new(Rack::MockRequest.env_for('/'))
      def last_response = Rack::Response.new
    end

    expect do
      other_test_class.new.assert_api_conform(status: 444)
    end.to raise_error(OpenapiFirst::Error)
  end
end

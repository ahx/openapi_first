# frozen_string_literal: true

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

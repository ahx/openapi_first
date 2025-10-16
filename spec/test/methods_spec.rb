# frozen_string_literal: true

require 'minitest'

RSpec.describe OpenapiFirst::Test::Methods do
  it 'includes PlainHelpers when included' do
    test_class = Class.new do
      include OpenapiFirst::Test::Methods
    end
    expect(test_class.included_modules).to include(OpenapiFirst::Test::PlainHelpers)
  end

  it 'raises OpenapiFirst::Error when assertion fails' do
    OpenapiFirst::Test.register('./examples/openapi.yaml')
    test_class = Class.new do
      include OpenapiFirst::Test::Methods

      def last_request = Rack::Request.new(Rack::MockRequest.env_for('/'))
      def last_response = Rack::Response.new
    end

    expect do
      test_class.new.assert_api_conform(status: 444)
    end.to raise_error(OpenapiFirst::Error)
  end

  context 'with RSpec' do
    context 'with metadata', api: :v1 do
      include OpenapiFirst::Test::Methods
      include Rack::Test::Methods

      it 'targets that api when calling assert_api_conform' do
        expect do
          assert_api_conform(status: 200)
        end.to raise_error(OpenapiFirst::NotRegisteredError) do |ex|
          expect(ex.message).to start_with("API description ':v1' not found.")
        end
      end
    end

    context 'with an [api:] option', api: :v2 do
      include OpenapiFirst::Test::Methods[api: :v1]

      it 'targets the api from the argument when calling assert_api_conform' do
        expect do
          assert_api_conform(status: 200)
        end.to raise_error(OpenapiFirst::NotRegisteredError) do |ex|
          expect(ex.message).to start_with("API description ':v1' not found.")
        end
      end
    end

    context 'with an [Application] argument and metadata', api: :v2 do
      include OpenapiFirst::Test::Methods[->(_) { Rack::Response.new('hey').finish }]
      include Rack::Test::Methods

      it 'targets that api when calling the app' do
        OpenapiFirst::Test.register('./examples/openapi.yaml', as: :v2)

        get('/')

        expect(last_request.env[OpenapiFirst::REQUEST].operation_id).to eq('example#root')
      end
    end
  end

  context 'with Minitest' do
    it 'includes MinitestHelpers when included' do
      minitest_class = Class.new(Minitest::Test) do
        include OpenapiFirst::Test::Methods
      end
      expect(minitest_class.included_modules).to include(OpenapiFirst::Test::MinitestHelpers)
    end

    it 'raises Minitest::Assertion when assertion fails' do
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
  end

  context 'with [arguments]' do
    it 'adds an app method that wraps the default API' do
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

    it 'adds an assert_api_conform method that targets the specified API' do
      OpenapiFirst::Test.register('./examples/openapi.yaml', as: :v1)
      test_class = Class.new do
        include OpenapiFirst::Test::Methods[api: :v1]

        def last_request = Rack::Request.new(Rack::MockRequest.env_for('/'))
        def last_response = Rack::Response.new
      end

      expect(test_class.new.openapi_first_default_api).to eq(:v1)

      expect do
        test_class.new.assert_api_conform(status: 444)
      end.to raise_error(OpenapiFirst::Error)
    end

    it 'adds an assert_api_conform method that still can target another API' do
      OpenapiFirst::Test.register('./examples/openapi.yaml', as: :v1)
      test_class = Class.new do
        include OpenapiFirst::Test::Methods[api: :v1]

        def last_request = Rack::Request.new(Rack::MockRequest.env_for('/'))
        def last_response = Rack::Response.new
      end

      expect do
        test_class.new.assert_api_conform(status: 444, api: :other)
      end.to raise_error(OpenapiFirst::NotRegisteredError) do |ex|
        expect(ex.message).to start_with("API description ':other' not found.")
      end
    end

    it 'does not add an app method if app is nil' do
      OpenapiFirst::Test.register('./examples/openapi.yaml', as: :v1)

      minitest_class = Class.new(Minitest::Test) do
        include OpenapiFirst::Test::Methods[api: :v1]
      end

      expect(minitest_class.included_modules).to include(OpenapiFirst::Test::MinitestHelpers)
      expect(minitest_class.new(1).respond_to?(:app)).to eq(false)
    end
  end
end

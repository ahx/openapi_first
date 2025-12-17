# frozen_string_literal: true

require 'minitest'

RSpec.describe OpenapiFirst::Test do
  let(:definition) { OpenapiFirst.load('./examples/openapi.yaml') }

  let(:app) do
    Class.new do
      def call(_env)
        Rack::Response.new.finish
      end
    end
  end

  describe '.observe' do
    it 'injects request/response validation in the app' do
      described_class.register(definition, as: :some)
      described_class.observe(app, api: :some)

      expect(definition).to receive(:validate_request)
      expect(definition).to receive(:validate_response)

      app.new.call({})
    end
  end

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

    it 'can register multiple OADs' do
      described_class.register('./spec/data/dice.yaml')
      described_class.register('./examples/openapi.yaml', as: :mine)
      expect(described_class[:default].filepath).to eq('./spec/data/dice.yaml')
      expect(described_class[:mine].filepath).to eq('./examples/openapi.yaml')
    end

    it 'can register a Definition object' do
      definition = OpenapiFirst.load('./examples/openapi.yaml')
      described_class.register(definition, as: :from_definition)
      expect(described_class[:from_definition]).to eq(definition)
    end

    it 'raises an error if the same API description is registered twice' do
      described_class.register('./examples/openapi.yaml')
      expect do
        described_class.register('./examples/openapi.yaml')
      end.to raise_error(OpenapiFirst::AlreadyRegisteredError)
    end
  end

  describe '.setup' do
    it 'registers an API description' do
      described_class.setup { |test| test.register('./examples/openapi.yaml') }
      expect(described_class.definitions[:default].filepath).to eq(OpenapiFirst.load('./examples/openapi.yaml').filepath)
    end

    it 'observes an app' do
      described_class.setup do |test|
        test.register(definition, as: :some)
        test.observe(app, api: :some)
      end

      expect(definition).to receive(:validate_request)
      app.new.call({})
    end

    it 'observes multiple apps' do
      other_app = Class.new do
        def call(_env)
          Rack::Response.new.finish
        end
      end

      described_class.setup do |test|
        test.register(definition, as: :some)
        test.observe(app, api: :some)
        test.observe(other_app, api: :some)
      end

      expect(definition).to receive(:validate_request).twice
      app.new.call({})
      other_app.new.call({})
    end

    it 'sets up minimum_coverage' do
      described_class.setup do |test|
        test.register('./examples/openapi.yaml')
        test.minimum_coverage = 100
      end
      expect(described_class.definitions[:default].filepath).to eq(OpenapiFirst.load('./examples/openapi.yaml').filepath)
    end

    it 'can skip_response_coverage' do
      described_class.setup do |test|
        test.register('./examples/openapi.yaml')
        test.skip_response_coverage { |res| res.status == '401' }
      end
      expect(described_class::Coverage.result.plans.first.tasks.count).to eq(2)
    end

    it 'can skip_coverage for whole routes' do
      described_class.setup do |test|
        test.register('./spec/data/petstore.yaml')
        test.skip_coverage { |path, request_method| path == '/pets' && request_method == 'POST' }
      end
      route_tasks = described_class::Coverage.result.plans.first.routes
      expect(route_tasks.map { |route| [route.path, route.request_method] }).to eq([['/pets', 'GET'], ['/pets/{petId}', 'GET']])
    end

    it 'can skip_coverage for paths' do
      described_class.setup do |test|
        test.register('./spec/data/petstore.yaml')
        test.skip_coverage { |path| path == '/pets' }
      end
      route_tasks = described_class::Coverage.result.plans.first.routes
      expect(route_tasks.map { |route| [route.path, route.request_method] }).to eq([['/pets/{petId}', 'GET']])
    end

    it 'is okay if no block is given if an OAD is registered ' do
      OpenapiFirst.register('./spec/data/dice.yaml', as: :dice)
      expect(described_class.setup)
    end

    it 'returns the globally registered OADs if nothing was registered inside the block' do
      oad = OpenapiFirst.load('./spec/data/dice.yaml')
      OpenapiFirst.register(oad, as: :dice)

      described_class.setup { |_test| } # rubocop:disable Lint/EmptyBlock

      expect(described_class.definitions).to be(OpenapiFirst.definitions)
    end

    it 'raises an error if no API description was registered' do
      expect do
        described_class.setup { |_test| } # rubocop:disable Lint/EmptyBlock
      end.to raise_error OpenapiFirst::NotRegisteredError
    end
  end

  describe '#handle_exit' do
    let(:configuration) { described_class.configuration }

    before do
      configuration.report_coverage = true
    end

    it 'reports coverage and fails' do
      expect(OpenapiFirst::Test).to receive(:report_coverage)
      expect do
        described_class.handle_exit
      end.to raise_error(SystemExit)
    end

    context 'with full coverage' do
      let(:definition) do
        OpenapiFirst.parse(YAML.load(%(
          openapi: 3.1.0
          info:
            title: Dice
            version: 1
          paths:
            "/roll":
              post:
                responses:
                  '200':
                    content:
                      application/json:
                        schema:
                          type: integer
                          min: 1
                          max:
        )))
      end

      before do
        valid_request = Rack::Request.new(Rack::MockRequest.env_for('/roll', method: 'POST'))
        valid_response = Rack::Response[200, { 'content-type' => 'application/json' }, ['1']]
        OpenapiFirst::Test.setup { |test| test.register(definition) }
        definition.validate_request(valid_request)
        definition.validate_response(valid_request, valid_response)
      end

      it 'does not fail' do
        expect do
          described_class.handle_exit
        end.not_to raise_error
      end
    end

    context 'with report_coverage = true' do
      before do
        configuration.report_coverage = true
      end

      it 'reports coverage' do
        expect(OpenapiFirst::Test).to receive(:report_coverage)
        expect do
          described_class.handle_exit
        end.to raise_error(SystemExit)
      end
    end

    context 'with report_coverage = false' do
      before do
        configuration.report_coverage = false
      end

      it 'does not report coverage' do
        expect(OpenapiFirst::Test).not_to receive(:report_coverage)

        described_class.handle_exit
      end
    end

    context 'with report_coverage = :warn' do
      before do
        configuration.report_coverage = :warn
      end

      it 'reports coverage, but does not fail' do
        expect(OpenapiFirst::Test).to receive(:report_coverage)

        described_class.handle_exit
      end
    end
  end

  describe '.report_coverage' do
    let(:output) { StringIO.new }

    before do
      described_class.setup do |test|
        test.register('./spec/data/dice.yaml')
      end

      allow($stdout).to receive(:puts).and_invoke(output.method(:puts))
    end

    it 'reports 50% if half of requests/responses have been tracked' do
      definition = OpenapiFirst.load('./spec/data/dice.yaml')
      valid_request = Rack::Request.new(Rack::MockRequest.env_for('/roll', method: 'POST'))
      definition.validate_request(valid_request, raise_error: true)
      # Response not tracked

      described_class.report_coverage
      expect(output.string).to include('API validation coverage for ./spec/data/dice.yaml: 50.0%')
    end

    it 'reports 100% if all requests/responses have been tracked' do
      definition = OpenapiFirst.load('./spec/data/dice.yaml')
      valid_request = Rack::Request.new(Rack::MockRequest.env_for('/roll', method: 'POST'))
      definition.validate_request(valid_request, raise_error: true)

      response = Rack::Response.new('4')
      response.content_type = 'application/json'
      definition.validate_response(valid_request, response, raise_error: true)

      described_class.report_coverage
      expect(output.string).to include('API validation coverage for ./spec/data/dice.yaml: 100%')
    end

    context 'when passing verbose: true' do
      it 'lists all requests/responses' do
        definition = OpenapiFirst.load('./spec/data/dice.yaml')
        valid_request = Rack::Request.new(Rack::MockRequest.env_for('/roll', method: 'POST'))
        definition.validate_request(valid_request, raise_error: true)

        response = Rack::Response.new('4')
        response.content_type = 'application/json'
        definition.validate_response(valid_request, response, raise_error: true)

        described_class.report_coverage(verbose: true)

        expected_output = [
          '✓ POST /roll',
          '  ✓  200(application/json)'
        ]
        expect(output.string).to include(*expected_output)
      end
    end

    context 'with no API description registered' do
      before do
        described_class.definitions.clear
      end

      it 'reports no detected requests by default' do
        output = StringIO.new
        allow($stdout).to receive(:puts).and_invoke(output.method(:puts))
        described_class.report_coverage
        expect(output.string).to include('Coverage did not detect any API requests')
      end
    end
  end

  describe '.app' do
    let(:filename) { './spec/data/dice.yaml' }
    let(:oad) { OpenapiFirst.load(filename) }

    let(:original_app) do
      double(:original_app,
             call: [200, { 'content-type' => 'application/json' }, ['1']],
             delegated_to_inner_app?: true)
    end

    let(:app) do
      described_class.app(original_app, api: oad)
    end

    include Rack::Test::Methods

    it 'silently adds request and response validation' do
      called = []
      oad.config.after_request_validation do
        called << :request
      end

      oad.config.after_response_validation do
        called << :response
      end

      post '/roll'

      expect(called).to eq(%i[request response])
    end

    it 'delegates missing methods to the inner app' do
      expect(app.delegated_to_inner_app?).to be true
    end

    it 'adds last validated request, reponse in the rack env' do
      post '/roll'

      last_env = last_request.env
      expect(last_env[described_class::REQUEST]).to be_a(OpenapiFirst::ValidatedRequest)
      expect(last_env[described_class::RESPONSE]).to be_a(OpenapiFirst::ValidatedResponse)
    end

    context 'when using registered OAD' do
      let(:app) do
        described_class.app(
          ->(_env) { [200, { 'content-type' => 'application/json' }, ['1']] },
          api: :mars_attack
        )
      end

      let(:oad) do
        described_class.register(filename, as: :mars_attack)
      end

      after do
        described_class.definitions.clear
      end

      it 'silently adds request and response validation' do
        called = []
        oad.config.after_request_validation do
          called << :request
        end

        oad.config.after_response_validation do
          called << :response
        end

        post '/roll'

        expect(called).to eq(%i[request response])
      end
    end
  end

  describe '.install' do
    it 'installs global hooks' do
      described_class.install

      config = OpenapiFirst.configuration
      expect(config.after_request_validation).not_to be_empty
      expect(config.after_response_validation).not_to be_empty
    end

    it 'does not install hooks multiple times' do
      2.times { described_class.install }

      config = OpenapiFirst.configuration
      expect(config.after_request_validation.count).to eq(1)
      expect(config.after_response_validation.count).to eq(1)
    end

    let(:filename) { './spec/data/dice.yaml' }
    let(:oad) { OpenapiFirst.load(filename) }

    context 'after_request_validation hook' do
      let(:invalid_request) do
        OpenapiFirst::ValidatedRequest.new(
          Rack::Request.new(Rack::MockRequest.env_for('/')),
          error: OpenapiFirst::Failure.new(:invalid_body)
        )
      end

      it 'raises an error for an invalid request' do
        described_class.install

        config = OpenapiFirst.configuration
        expect(config.after_request_validation.count).to eq(1)
        expect do
          config.after_request_validation.first.call(invalid_request, oad)
        end.to raise_error(OpenapiFirst::RequestInvalidError)
      end

      it 'does not raise an error for an invalid request when raises_error_for_request returns false' do
        described_class.setup do |test|
          test.register(oad)
          test.raise_error_for_request = ->(_validated_request) { false }
        end

        config = OpenapiFirst.configuration
        expect(config.after_request_validation.count).to eq(1)
        expect do
          config.after_request_validation.first.call(invalid_request, oad)
        end.not_to raise_error
      end
    end

    context 'after_response_validation hook' do
      let(:invalid_response) do
        OpenapiFirst::ValidatedResponse.new(
          Rack::Response.new('{"foo": "bar"}', 200, { 'Content-Type' => 'application/json' }),
          error: OpenapiFirst::Failure.new(:invalid_response_body)
        )
      end

      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/'))
      end

      it 'raises an error for an invalid response' do
        described_class.install

        config = OpenapiFirst.configuration
        expect(config.after_response_validation.count).to eq(1)
        expect do
          config.after_response_validation.first.call(invalid_response, rack_request)
        end.to raise_error(OpenapiFirst::ResponseInvalidError)
      end

      it 'does not raise an error for an invalid response when raises_error_for_response returns false' do
        described_class.setup do |test|
          test.register(oad)
          test.raise_error_for_response = ->(_validated_response, _rack_request) { false }
        end

        config = OpenapiFirst.configuration
        expect(config.after_response_validation.count).to eq(1)
        expect do
          config.after_response_validation.first.call(invalid_response, rack_request)
        end.not_to raise_error
      end
    end
  end

  describe '.[]' do
    it 'complaints about an unknown api' do
      expect do
        described_class[:default]
      end.to raise_error(OpenapiFirst::NotRegisteredError)
    end

    it 'complaints about an unknown api' do
      expect do
        described_class[:mine]
      end.to raise_error(OpenapiFirst::NotRegisteredError)
    end

    it 'just returns a Definition' do
      oad = definition
      expect(described_class[oad]).to be(oad)
    end
  end

  describe 'handling invalid requests' do
    let(:definition) do
      OpenapiFirst.parse(
        {
          'openapi' => '3.1.0',
          'paths' => {
            '/stuff/{id}' => {
              'get' => {
                'parameters' => [
                  {
                    'name' => 'id',
                    'in' => 'path',
                    'required' => true,
                    'schema' => {
                      'type' => 'integer'
                    }
                  }
                ],
                'responses' => {
                  '200' => {
                    'descrition' => 'Ok'
                  }
                }
              }
            }
          }
        },
        filepath: 'somefile'
      )
    end

    let(:app) do
      described_class.app(
        ->(_env) { [200, { 'content-type' => 'application/json' }, ['foo']] },
        spec: definition
      )
    end

    before(:each) do
      described_class.setup do |test|
        test.register(definition)
        test.report_coverage = false
      end
    end

    it 'raises no error, but tracks the request' do
      app.call(Rack::MockRequest.env_for('/stuff/nostring'))

      expect(described_class::Coverage.result.coverage).to eq 50
    end
  end

  describe 'handling unknown requests paths' do
    let(:app) do
      described_class.app(
        ->(_env) { [200, { 'content-type' => 'application/json' }, ['foo']] },
        spec: definition
      )
    end

    before(:each) do
      described_class.setup do |test|
        test.register(definition)
        test.report_coverage = false
      end
    end

    it 'raises an error' do
      expect do
        app.call(Rack::MockRequest.env_for('/unknown'))
      end.to raise_error(OpenapiFirst::NotFoundError)
    end

    context 'with raise_error_for_request returning false' do
      before(:each) do
        described_class.uninstall
        described_class.setup do |test|
          test.register(definition)
          test.ignore_unknown_requests = false
          test.report_coverage = false
        end
      end

      it 'does not raise an error' do
        called = false
        described_class.configuration.raise_error_for_request = lambda do |validated_request|
          called = true
          expect(validated_request).to be_a(OpenapiFirst::ValidatedRequest)
          false
        end

        expect do
          app.call(Rack::MockRequest.env_for('/unknown'))
        end.not_to raise_error
        expect(called).to eq(true)
      end
    end

    context 'with ignore_unknown_requests = true' do
      before(:each) do
        described_class.uninstall
        described_class.setup do |test|
          test.register(definition)
          test.ignore_unknown_requests = true
          test.report_coverage = false
        end
      end

      it 'does not raise an error' do
        expect do
          app.call(Rack::MockRequest.env_for('/unknown'))
        end.not_to raise_error
      end
    end
  end

  describe 'handling invalid responses' do
    let(:definition) do
      OpenapiFirst.parse(YAML.load(%(
        openapi: 3.1.0
        info:
          title: Dice
          version: 1
        paths:
          "/roll":
            post:
              responses:
                '200':
                  content:
                    application/json:
                      schema:
                        type: integer
                        min: 1
                        max:
      )))
    end

    let(:app) do
      described_class.app(
        ->(_env) { [200, { 'content-type' => 'application/json' }, ['foo']] },
        spec: definition
      )
    end

    before(:each) do
      described_class.setup do |test|
        test.register(definition)
      end
    end

    it 'raises an error' do
      expect do
        app.call(Rack::MockRequest.env_for('/roll', method: 'POST'))
      end.to raise_error(OpenapiFirst::ResponseInvalidError)
    end

    context 'with raise_error_for_response returning false' do
      before(:each) do
        described_class.uninstall
        described_class.setup do |test|
          test.register(definition)
        end
      end

      it 'does not raise an error' do
        called = false
        described_class.configuration.raise_error_for_response = lambda do |validated_response, rack_request|
          called = true
          expect(validated_response).to be_a(OpenapiFirst::ValidatedResponse)
          expect(rack_request).to be_a(Rack::Request)
          false
        end

        expect do
          app.call(Rack::MockRequest.env_for('/roll', method: 'POST'))
        end.not_to raise_error
        expect(called).to eq(true)
      end
    end

    context 'with response_raise_error = false' do
      before(:each) do
        described_class.uninstall
        described_class.setup do |test|
          test.register(definition)
          test.response_raise_error = false
          test.report_coverage = false
        end
      end

      it 'does not raise an error' do
        expect do
          app.call(Rack::MockRequest.env_for('/roll', method: 'POST'))
        end.not_to raise_error
      end
    end
  end

  describe 'handling unknown response status' do
    let(:definition) do
      OpenapiFirst.load('./spec/data/dice.yaml')
    end

    let(:app) do
      described_class.app(
        ->(_env) { [302, { 'content-type' => 'application/json' }, ['5']] },
        spec: definition
      )
    end

    before(:each) do
      described_class.setup do |test|
        test.register(definition)
      end
    end

    context 'when response status is unknown' do
      it 'raises an error' do
        expect do
          app.call(Rack::MockRequest.env_for('/roll', method: 'POST'))
        end.to raise_error(OpenapiFirst::ResponseNotFoundError)
      end
    end

    context 'when response content-type is unknown' do
      it 'raises an error' do
        expect do
          app.call(Rack::MockRequest.env_for('/roll', method: 'POST'))
        end.to raise_error(OpenapiFirst::ResponseNotFoundError)
      end
    end

    context 'with ignored_unknown_status' do
      before(:each) do
        described_class.configuration.ignored_unknown_status << 302
      end

      it 'does not raise an error' do
        expect do
          app.call(Rack::MockRequest.env_for('/roll', method: 'POST'))
        end.not_to raise_error
      end
    end

    context 'with ignored_unknown_status =' do
      before(:each) do
        described_class.configuration.ignored_unknown_status = [302]
      end

      it 'does not raise an error' do
        expect do
          app.call(Rack::MockRequest.env_for('/roll', method: 'POST'))
        end.not_to raise_error
      end
    end

    context 'with ignore_unknown_response_status = true' do
      before(:each) do
        described_class.configuration.ignore_unknown_response_status = true
      end

      it 'does not raise an error' do
        expect do
          app.call(Rack::MockRequest.env_for('/roll', method: 'POST'))
        end.not_to raise_error
      end
    end
  end
end

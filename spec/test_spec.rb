# frozen_string_literal: true

require 'minitest'

RSpec.describe OpenapiFirst::Test do
  after(:each) do
    described_class.definitions.clear
    OpenapiFirst::Test::Coverage.uninstall
    OpenapiFirst::Test::Coverage.reset
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

    it 'uses filepath as key for Definition objects with filepath' do
      # Register a definition with filepath and start tracking
      definition = OpenapiFirst.load('./spec/data/dice.yaml')
      described_class.register(definition, as: :with_filepath)
      OpenapiFirst::Test::Coverage.start

      # Verify the plan was registered with the filepath key
      filepath = './spec/data/dice.yaml'
      plan = OpenapiFirst::Test::Coverage.current_run[filepath]

      expect(plan).not_to be_nil
      expect(plan.filepath).to eq(filepath)
      expect(plan.api_identifier).to eq(filepath)
    end

    it 'uses the definition key for Definition objects without filepath' do
      # Create a definition without filepath
      dice_hash = YAML.load_file('./spec/data/dice.yaml')
      dice_hash['info'] = {
        'title' => 'Dice API',
        'version' => '1.0.0'
      }
      definition = OpenapiFirst.parse(dice_hash)

      # Register and start tracking
      described_class.register(definition, as: :without_filepath)
      OpenapiFirst::Test::Coverage.start

      expected_key = definition.key
      plan = OpenapiFirst::Test::Coverage.current_run[expected_key]

      # Verify the plan was registered with the definition key
      expect(plan).to be_a(OpenapiFirst::Test::Coverage::Plan)
      expect(plan.api_identifier).to eq(expected_key)
    end

    it 'raises an error if the same API description is registered twice' do
      described_class.register('./examples/openapi.yaml')
      expect do
        described_class.register('./examples/openapi.yaml')
      end.to raise_error(described_class::AlreadyRegisteredError)
    end
  end

  describe '.setup' do
    it 'registers an API description' do
      described_class.setup { |test| test.register('./examples/openapi.yaml') }
      expect(described_class.definitions[:default].filepath).to eq(OpenapiFirst.load('./examples/openapi.yaml').filepath)
    end

    it 'sets up minimum_coverage' do
      described_class.setup do |test|
        test.register('./examples/openapi.yaml')
        test.minimum_coverage = 100
      end
      expect(described_class.definitions[:default].filepath).to eq(OpenapiFirst.load('./examples/openapi.yaml').filepath)
    end

    it 'can skip responses for coverage' do
      described_class.setup do |test|
        test.register('./examples/openapi.yaml')
        test.skip_response_coverage { |res| res.status == '401' }
      end
      expect(described_class::Coverage.plans.first.tasks.count).to eq(2)
    end

    it 'raises an error if no block is given' do
      expect do
        described_class.setup
      end.to raise_error ArgumentError
    end

    it 'raises an error if no API description was registered' do
      expect do
        described_class.setup { |_test| } # rubocop:disable Lint/EmptyBlock
      end.to raise_error described_class::NotRegisteredError
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

    it 'reports 50% if halfe of requests/responses have been tracked' do
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
      expect(output.string).to include('API validation coverage for ./spec/data/dice.yaml: 100.0%')
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

      it 'reports 0% by default' do
        output = StringIO.new
        allow($stdout).to receive(:puts).and_invoke(output.method(:puts))
        described_class.report_coverage
        expect(output.string).to include('0%')
      end
    end
  end

  describe '.app' do
    let(:filename) { './spec/data/dice.yaml' }
    let(:oad) { OpenapiFirst.load(filename) }

    let(:app) do
      described_class.app(
        ->(_env) { [200, { 'content-type' => 'application/json' }, ['1']] },
        spec: oad
      )
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

  describe '.[]' do
    it 'complaints about an unknown api' do
      expect do
        described_class[:default]
      end.to raise_error(OpenapiFirst::Test::NotRegisteredError)
    end

    it 'complaints about an unknown api' do
      expect do
        described_class[:mine]
      end.to raise_error(OpenapiFirst::Test::NotRegisteredError)
    end
  end
end

# frozen_string_literal: true

require 'minitest'

RSpec.describe OpenapiFirst::Test do
  after(:each) do
    described_class.definitions.clear
    OpenapiFirst::Test::Coverage.stop
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

    it 'can register an OAD with a custom name' do
      described_class.register('./examples/openapi.yaml', as: :mine)
      expect(described_class[:mine].filepath).to eq('./examples/openapi.yaml')
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
    it 'reports 0% by default' do
      output = StringIO.new
      allow($stdout).to receive(:puts).and_invoke(output.method(:puts))
      described_class.report_coverage
      expect(output.string).to include('0%')
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
